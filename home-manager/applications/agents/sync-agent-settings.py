import json
import os
import shutil
import sys
import tempfile
import tomllib

import tomli_w


def read_json(path):
    if is_missing_or_empty(path):
        return {}

    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def write_json(path, value):
    content = json.dumps(value, indent=2, sort_keys=True) + "\n"
    atomic_write(path, content)


def read_toml(path):
    if is_missing_or_empty(path):
        return {}

    with open(path, "rb") as f:
        return tomllib.load(f)


def write_toml(path, value):
    atomic_write(path, tomli_w.dumps(value, multiline_strings=True))


def is_missing_or_empty(path):
    return not os.path.exists(path) or os.path.getsize(path) == 0


def atomic_write(path, content):
    directory = os.path.dirname(path)
    fd, tmp_path = tempfile.mkstemp(prefix=".tmp-", dir=directory, text=True)

    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(content)
        os.replace(tmp_path, path)
    finally:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)


def get_path(value, path):
    current = value

    for key in path:
        if not isinstance(current, dict) or key not in current:
            return None
        current = current[key]

    return current


def set_path(value, path, managed):
    current = value

    for key in path[:-1]:
        child = current.get(key)
        if not isinstance(child, dict):
            child = {}
            current[key] = child
        current = child

    current[path[-1]] = managed


def delete_path(value, path):
    current = value
    parents = []

    for key in path[:-1]:
        if not isinstance(current, dict) or key not in current:
            return
        parents.append((current, key))
        current = current[key]

    if isinstance(current, dict):
        current.pop(path[-1], None)

    remove_empty_parents(parents)


def remove_empty_parents(parents):
    for parent, key in reversed(parents):
        child = parent.get(key)
        if isinstance(child, dict) and not child:
            parent.pop(key, None)
        else:
            break


def encode_paths(paths):
    return [list(path) for path in sorted(paths)]


def decode_paths(paths):
    return {tuple(path) for path in paths}


def json_managed_paths(managed):
    return {(key,) for key in managed.keys()}


def toml_managed_paths(managed):
    paths = set()

    for key, value in managed.items():
        if isinstance(value, dict):
            paths.update((key, child_key) for child_key in value.keys())
        else:
            paths.add((key,))

    return paths


def replace_symlink(path):
    if not os.path.islink(path):
        return

    target = os.path.realpath(path)
    os.unlink(path)

    if os.path.exists(target):
        shutil.copyfile(target, path)


CONFIG_FORMATS = {
    "json": {
        "read": read_json,
        "write": write_json,
        "managed_paths": json_managed_paths,
    },
    "toml": {
        "read": read_toml,
        "write": write_toml,
        "managed_paths": toml_managed_paths,
    },
}


def sync(kind, target_path, fragment_path, state_path):
    config_format = CONFIG_FORMATS.get(kind)
    if config_format is None:
        raise ValueError(f"Unsupported config kind: {kind}")

    os.makedirs(os.path.dirname(target_path), exist_ok=True)
    os.makedirs(os.path.dirname(state_path), exist_ok=True)
    replace_symlink(target_path)

    config = config_format["read"](target_path)
    managed = config_format["read"](fragment_path)
    state = read_json(state_path)

    if not isinstance(config, dict):
        raise TypeError(f"{target_path} must contain a top-level object/table")
    if not isinstance(managed, dict):
        raise TypeError(f"{fragment_path} must contain a top-level object/table")

    previous_paths = decode_paths(state.get("managed_paths", []))
    current_paths = config_format["managed_paths"](managed)

    remove_previously_managed_paths(config, previous_paths - current_paths, kind)
    apply_managed_paths(config, managed, current_paths)

    config_format["write"](target_path, config)
    write_json(state_path, {"managed_paths": encode_paths(current_paths)})


def remove_previously_managed_paths(config, paths, kind):
    for path in sorted(paths, key=len, reverse=True):
        if kind == "json" and path == ("$schema",):
            continue
        delete_path(config, path)


def apply_managed_paths(config, managed, paths):
    for path in sorted(paths, key=len):
        set_path(config, path, get_path(managed, path))


if __name__ == "__main__":
    sync(*sys.argv[1:])

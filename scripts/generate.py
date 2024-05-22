import os
import os.path
import re
from typing import List

from nvim_doc_tools import (
    Vimdoc,
    VimdocSection,
    convert_md_section_to_vimdoc,
    format_md_table,
    generate_md_toc,
    leftright,
    parse_directory,
    read_nvim_json,
    render_md_api2,
    render_vimdoc_api2,
    replace_section,
    wrap,
)

HERE = os.path.dirname(__file__)
ROOT = os.path.abspath(os.path.join(HERE, os.path.pardir))
README = os.path.join(ROOT, "README.md")
DOC = os.path.join(ROOT, "doc")
VIMDOC = os.path.join(DOC, "stickybuf.txt")


def add_md_link_path(path: str, lines: List[str]) -> List[str]:
    ret = []
    for line in lines:
        ret.append(re.sub(r"(\(#)", "(" + path + "#", line))
    return ret


def update_md_api():
    types = parse_directory(os.path.join(ROOT, "lua"))
    funcs = types.files["stickybuf.lua"].functions
    lines = ["\n"] + render_md_api2(funcs, types, 3) + ["\n"]
    replace_section(
        README,
        r"^<!-- API -->$",
        r"^<!-- /API -->$",
        lines,
    )


def update_readme_toc():
    toc = ["\n"] + generate_md_toc(README, max_level=1) + ["\n"]
    replace_section(
        README,
        r"^<!-- TOC -->$",
        r"^<!-- /TOC -->$",
        toc,
    )


def update_commands_md():
    commands = read_nvim_json('require("stickybuf").get_all_commands()')
    lines = ["\n"]
    rows = []
    any_has_args = False
    for command in commands:
        if command.get("deprecated"):
            continue
        cmd = command["cmd"]
        if command["def"].get("bang"):
            cmd += "[!]"
        any_has_args = any_has_args or "args" in command
        rows.append(
            {
                "Command": "`" + cmd + "`",
                "Args": command.get("args", ""),
                "Description": command["def"]["desc"],
            }
        )
    cols = ["Command", "Args", "Description"]
    if not any_has_args:
        cols.remove("Args")
    lines.extend(format_md_table(rows, cols))
    lines.append("\n")
    replace_section(
        os.path.join(README),
        r"^## Commands",
        r"^#",
        lines,
    )


def get_commands_vimdoc() -> "VimdocSection":
    section = VimdocSection("Commands", "stickybuf-commands", ["\n"])
    commands = read_nvim_json('require("stickybuf").get_all_commands()')
    for command in commands:
        if command.get("deprecated"):
            continue
        cmd = command["cmd"]
        if command["def"].get("bang"):
            cmd += "[!]"
        if "args" in command:
            cmd += " " + command["args"]
        section.body.append(leftright(cmd, f"*:{command['cmd']}*"))
        section.body.extend(wrap(command["def"]["desc"], 4))
        section.body.append("\n")
    return section


def generate_vimdoc():
    doc = Vimdoc("stickybuf.txt", "stickybuf")
    types = parse_directory(os.path.join(ROOT, "lua"))
    funcs = types.files["stickybuf.lua"].functions
    doc.sections.extend(
        [
            get_commands_vimdoc(),
            VimdocSection(
                "API", "stickybuf-api", render_vimdoc_api2("stickybuf", funcs, types)
            ),
            convert_md_section_to_vimdoc(
                README,
                "^## Configuration",
                "^#",
                "options",
                "stickybuf-options",
            ),
        ]
    )

    with open(VIMDOC, "w", encoding="utf-8") as ofile:
        ofile.writelines(doc.render())


def main() -> None:
    """Update the README"""
    update_md_api()
    update_commands_md()
    update_readme_toc()
    generate_vimdoc()

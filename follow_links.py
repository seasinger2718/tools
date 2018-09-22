#!/usr/bin/env python3

import sys
import os
from os import path


def chase_link(file_path, indent=2):
    indent_prefix = indent * ' '
    print("{0}{1}".format(indent_prefix, file_path))
    if path.islink(file_path):
        target = os.readlink(file_path)
        if not path.isabs(target):
            base_dir = path.dirname(file_path)
            target = path.normpath(path.join(base_dir, target))
        chase_link(target, indent + 2)


def main(*args):
    for arg in args[0]:
        chase_link(arg)


if __name__ == "__main__":
    main(sys.argv[1:])
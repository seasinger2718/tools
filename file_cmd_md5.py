#!/usr/bin/env python3

import sys
import os
import os.path as path
import hashlib

IMAGE_EXTENSIONS=("jpeg", "jpg", "png")


def md5(file_name):
    """
    Calculates the md5 for a given file

    Args:
        file_name (str): File name

    Returns:
        md5 hex checksum
    """
    hash_md5 = hashlib.md5()
    with open(file_name, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()


def process_entry(file_or_dir, all_entries):
    """
    Process a single entry. Recurse if entry is a directory

    Args:
        file_or_dir (str): A file or directory path
        all_entries (dict): Accumulates entries

    Returns:
        None

    """

    if path.isdir(file_or_dir):
        for entry in os.listdir(file_or_dir):
            entry = path.join(file_or_dir, entry)
            if path.isdir(entry):
                process_entry(str(entry), all_entries)
            else:
                # Filter out files by extension
                extension = path.splitext(entry)[1][1:]
                if extension not in IMAGE_EXTENSIONS:
                    continue

                file_md5 = md5(entry)
                if file_md5 in all_entries:
                    file_list = all_entries[file_md5]
                    file_list.append(entry)
                else:
                    file_list = [entry]

                all_entries[file_md5] = file_list

    else:
        file_md5 = md5(file_or_dir)
        if file_md5 in all_entries:
            file_list = all_entries[file_md5]
            file_list.append(file_or_dir)
        else:
            file_list = [file_or_dir]

        all_entries[file_md5] = file_list

    return


def process_entries(*files_or_dirs):
    """
    Process a list of entries, either files or directories, and accumulate md5 entries

    Args:
        files_or_dirs (lst): List of files and/or directories

    Returns:
        None
    """

    all_entries = {}

    print("{0} :: {1} :: {2}".format("md5", "# matches", "file names"))

    for file_or_dir in files_or_dirs[0]:
        process_entry(file_or_dir, all_entries)

    for entry, entries_list in all_entries.items():

        total_matches = len(entries_list)
        print("{0} :: {1} :: {2}".format(entry, total_matches , entries_list))


def main(*args):
    process_entries(*args)
    sys.exit(0)


if __name__ == '__main__':
    main(sys.argv[1:])

#!/usr/bin/env python3


import sys
import os
from os import path
from glob import glob
import re
from datetime import datetime, timedelta

MODIFIED_ENTRY_SUFFIX_RE = re.compile("00\d")
MATCHING_ENTRY_SUFFIX_RE = re.compile("\d\d\d\d\d")
SEGMENT_SEPARATOR = "_"
MATCHING_ENTRY_DIFFERENCE_SECONDS_MAX = 2
MATCHING_ENTRY_DIFFERENCE_TIME_DELTA = timedelta(seconds=MATCHING_ENTRY_DIFFERENCE_SECONDS_MAX)



class FileEntry:

    def __init__(self):
        self.matching_file_entries = []
        self.original_path = None
        self.dirname = None
        self.base_name = None
        self.base_file_name_no_ext = None
        self.base_file_name_ext = None
        self.base_prefix = None
        self.processed = False
        self.renamed = False
        self.datetime = None
        self.new_base_name = None

    def add_matching_entry(self, new_entry):
        # Match on base_file_name_no_ext
        matching_entries = [matching_entry
                            for matching_entry in self.matching_file_entries
                            if matching_entry.base_file_name_no_ext == new_entry.base_file_name_no_ext]

        # If this one hasn't been seen before, add it
        if not matching_entries:
            self.matching_file_entries.append(new_entry)


def reverse(string):
    string = "".join(reversed(string))
    return string


def process_path(file_path, all_entries, rename_files_list):
    """
    Process a path.

    If a directory, every entry in the directory.
    If an entry, check to see whether it's been processed before.
    If not, see if it's close to something already known.

    Args:
        file_path (str): File path
        all_entries (dict): dict with all FileEntry instances
        rename_files_list (list[FileEntry]): List of FileEntry objects to be renamed.

    Returns:

    """
    if path.isdir(file_path):
        dir_match = path.join(file_path,"*")
        file_paths = list(glob(dir_match))
        if file_paths:
            file_paths.sort()
            for file_path_2 in file_paths:
                process_path(file_path_2, all_entries, rename_files_list)
    else:
        dir_name = path.dirname(file_path)
        base_file_name = path.basename(file_path)
        base_file_name_no_ext = path.splitext(base_file_name)[0]
        base_file_name_ext = path.splitext(base_file_name)[1]

        # Grab last segment of file name
        last_segment = reverse(reverse(base_file_name_no_ext).split(SEGMENT_SEPARATOR)[0])
        base_prefix = base_file_name_no_ext.replace(SEGMENT_SEPARATOR + last_segment , "")

        if MODIFIED_ENTRY_SUFFIX_RE.match(last_segment):
            # If file has already been processed,
            # just make sure there are appropriate entries,
            # but don't do anything else
            new_file_entry = FileEntry()
            new_file_entry.processed = True
            if base_file_name_no_ext not in all_entries:
                new_file_entry.original_path = file_path
                new_file_entry.dirname = dir_name
                new_file_entry.base_name = base_file_name
                new_file_entry.base_file_name_no_ext = base_file_name_no_ext
                new_file_entry.base_file_name_ext = base_file_name_ext
                new_file_entry.base_prefix = base_prefix

                all_entries[base_file_name] = new_file_entry

            if base_prefix in all_entries:
                existing_entry = all_entries[base_prefix]
                print("Processed: {0} already seen file with prefix {1} -- {2}".format(
                    base_file_name, base_prefix, existing_entry.base_name
                ))
            else:
                all_entries[base_prefix] = new_file_entry

        else:
            # If file hasn't been processed yet, look for possible matches
            # print("Not processed: {0}".format(base_file_name))

            if MATCHING_ENTRY_SUFFIX_RE.match(last_segment):

                # First look for known associated file
                new_file_entry = FileEntry()

                if base_file_name_no_ext not in all_entries:
                    new_file_entry.original_path = file_path
                    new_file_entry.dirname = dir_name
                    new_file_entry.base_name = base_file_name
                    new_file_entry.base_file_name_no_ext = base_file_name_no_ext
                    new_file_entry.base_file_name_ext = base_file_name_ext
                    new_file_entry.base_prefix = base_prefix

                    all_entries[base_file_name] = new_file_entry

                # Strip off last 3 digits of basename without extension to get likely match
                matching_base_file_name_no_ext = base_file_name_no_ext[:-3]
                matching_base_file_name = matching_base_file_name_no_ext + base_file_name_ext
                if matching_base_file_name in all_entries:
                    existing_entry = all_entries[matching_base_file_name]
                    existing_entry.add_matching_entry(new_file_entry)
                    print("Probable match : {0} already seen file with prefix {1} -- {2}".format(
                        base_file_name, base_prefix, existing_entry.base_name
                    ))

                    # Add to rename list
                    rename_files_list.append(existing_entry)

            else:
                # Don't know what kind of an entry this is

                # Can't do anything with prefix because this is an unknown entry type
                new_file_entry = FileEntry()

                # Try for a timestamp so time stamp differences can be compared
                # try:
                #     ftime = base_file_name_no_ext.split("_")
                #     file_datetime = datetime(int(ftime[0]),int(ftime[1]),int(ftime[2]),int(ftime[3]),int(ftime[4]),int(ftime[5]))
                #     new_file_entry.datetime = file_datetime
                # except Exception:
                #     pass

                if base_file_name_no_ext not in all_entries:
                    new_file_entry.original_path = file_path
                    new_file_entry.dirname = dir_name
                    new_file_entry.base_name = base_file_name
                    new_file_entry.base_file_name_no_ext = base_file_name_no_ext
                    new_file_entry.base_file_name_ext = base_file_name_ext
                    new_file_entry.base_prefix = base_prefix
                    all_entries[base_file_name] = new_file_entry
                    all_entries[base_file_name_no_ext] = new_file_entry
                    print("New entry: {0}".format(base_file_name))

                    # Not enough utility in matching
                    # possible_matches = find_match_by_datetime(new_file_entry, all_entries)
                    # if possible_matches:
                    #     # Skip current entry
                    #     possible_matches = [possible_match
                    #                         for possible_match in possible_matches
                    #                         if possible_match.base_name != new_file_entry.base_name
                    #                        ]
                    #     if possible_matches:
                    #         print("Possible match on datetime : {0} already seen similar file {1}".format(
                    #             base_file_name, possible_matches[0].base_name
                    #         ))
                else:
                    print("Error: New entry: {0} already matches something ".format(base_file_name))


def find_match_by_datetime(file_entry, all_entries, delta=MATCHING_ENTRY_DIFFERENCE_TIME_DELTA):
    """
    Look for timestamps that are close enough based on MATCHING_ENTRY_DIFFERENCE_SECONDS_MAX

    Only consider those objects which have a datetime entry

    Args:
        file_entry (obj): File entry to be matched
        delta (timedelta): Maximum difference

    Returns:
        Matching entries list(FileEntry)

    """

    matching_entries = [ matching_entry
                         for matching_key, matching_entry in all_entries.items()
                         if file_entry.datetime and
                            matching_entry.datetime and
                            (file_entry.datetime - matching_entry.datetime <= delta)
                         ]
    return matching_entries


def rename_files(rename_files_list):

    for rename_file_entry in rename_files_list:
        file_name_suffix = 0

        entries_to_rename = [rename_file_entry]
        entries_to_rename.extend(rename_file_entry.matching_file_entries)

        for entry_to_rename in entries_to_rename:
            original_file_path = entry_to_rename.original_path
            file_dir = entry_to_rename.dirname
            file_name_prefix =  entry_to_rename.base_prefix
            new_file_name = "{0}_{1}{2}".format(
                file_name_prefix, ("000" + str(file_name_suffix))[-3:], rename_file_entry.base_file_name_ext
            )
            new_file_path = "{0}/{1}".format(file_dir, new_file_name)
            print("Rename {0} to {1}".format(original_file_path, new_file_path))
            os.rename(original_file_path,new_file_path)
            entry_to_rename.renamed = True
            file_name_suffix = file_name_suffix + 1


def main(*args):
    # dict with all FileEntry instances
    # Indexed by:
    # - 1 file base name
    # - 2 file prefix
    all_entries = {}

    #  List of FileEntry instances to be renamed.
    rename_files_list = []

    for arg in args[0]:
        process_path(arg, all_entries, rename_files_list)

    rename_files(rename_files_list)


if __name__ == "__main__":
    main(sys.argv[1:])






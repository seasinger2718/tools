
from glob import glob
from os.path import join, realpath, dirname, getsize, getmtime, isfile
from os import pathsep, getcwd
from subprocess import call, run
from time import sleep
from selenium import webdriver

# region options for the live preview


path_to_webdriver = "/usr/local/bin/chromedriver_selenium"  # This is the path to the webdriver. Change this to where you put the driver.
update_delay = 0.2  # The update delay when some file change is detected.
render_math = True  # True if you want to re-render math every time an update is made; otherwise False
source_folder_name = "source"
build_folder_name = "build"

driver = webdriver.Chrome(path_to_webdriver)  # Change "Chrome" to the right type of browser driver you are using

# endregion



script_path = dirname(realpath(__file__))
active_dir = getcwd()
#print("rst_preview script_path {0}".format(script_path))
source_path = join(active_dir, source_folder_name)
#print("rst_preview source_path {0}".format(source_path))
source_path_len = len(source_path) + len(pathsep)
build_path = join(active_dir, build_folder_name, "html")
#print("rst_preview build_path {0}".format(build_path))
rst_files = glob(join(active_dir, '**/*.rst'), recursive=True)
#print("rst_preview rst_files {0}".format(rst_files))
size_dict = {}
for rst_file in rst_files:
    size_dict[rst_file] = [getsize(rst_file), getmtime(rst_file), 0]

while True:
    for rst_file in rst_files:
        if isfile(rst_file):
            record = size_dict[rst_file]
            new_size = getsize(rst_file)
            new_mtime = getmtime(rst_file)
            if record[0] != new_size or record[1] < new_mtime:  # Checks if file size or latest modify time change
                html_file = join(build_path, rst_file[source_path_len: -4] + ".html")
                #call("/usr/local/bin/sphinx-build -M html %s %s" % (source_folder_name, build_folder_name))
                run(['/usr/local/bin/sphinx-build', '-M', 'html', source_folder_name, build_folder_name])
                if record[2] == 0:  # open the corresponding html for the rst file under editing
                    html_file_url = "file://{0}".format(html_file)
                    print("DEBUG rst_preview html_file_url {0}".format(html_file_url))
                    driver.get(html_file_url)
                else:
                    with open(html_file, 'r', encoding="utf-8") as content_file:
                        content = content_file.read()
                    new_body_start_idx = content.index("<body")
                    new_body_start_idx = content.index(">", new_body_start_idx) + 1
                    content = content[new_body_start_idx:content.rindex("</body>")].strip()
                    driver.execute_script('document.getElementsByTagName("body")[0].innerHTML = arguments[0]', content)  # make the update
                    if render_math:
                        driver.execute_script('MathJax.Hub.Queue(["Typeset",MathJax.Hub])')

                record[0] = new_size
                record[1] = new_mtime
                record[2] += 1

    sleep(update_delay)

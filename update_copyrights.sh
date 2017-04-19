#!/bin/bash

# Script to add or update copyright messages
#   command-line
#     update_copyrights file_name

# Set variables and documentation strings
EXTENSIONS=".rb .yml .sql .rhtml .gawk"
COPYRIGHT_YEARS="2005-2006"

# Save command line parameters
original=$1

# Backup file
backup=$1.bak
#cp -f $original $backup

# Determine basename and extension
original_basename=`basename $original`
case $original_basename in
  *.rb ) file_type=".rb" ;;
esac

# Do file-type specific stuff
if [ "$file_type" == ".rb" ]
then
  echo filetype is rb
  has_id_string=`grep -c Id: $original`
  
  cat <<~ HEADER_RB
#--
#  $original_basename
#
#  $Id: update_copyrights.sh 440 2006-02-08 14:01:13Z tracy $
#++
#  Controller UID Type maintenance.
#--
#
# (c) 2005 Dynamic Data Network Inc tracy@dynamicdatanetwork.com
#
# THIS SOFTWARE IS PROVIDED BY DYNAMIC DATA NETWORK INC. ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
HEADER_RB  
  
  
fi

# Step 2


#for extension in $EXTENSIONS
#do
#  echo $extension
#  case $extension in
#    ".rb" ) echo rb ;;
#    ".yml") echo yml ;;
#    ".sql")  echo sql ;;
#    ".rhtml")  echo rhtml ;;
#    ".gawk")  echo gawk ;;
#  esac  
#  #find . -type f -name \*$extension
#done
  
#word=Linux
#letter_sequence=inu
#if echo "$word" | grep −q "$letter_sequence"
# The "−q" option to grep suppresses output.
#then
#echo "$letter_sequence found in $word"
#else
#echo "$letter_sequence not found in $word"
#fi
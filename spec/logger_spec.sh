#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

# By default behave like syslog
#
# Aka print lower log levels and up. Basically if I set LOG_LEVEL to say notice
# I shouldn't get info/debug output
#
# Default is to set log level to warning, so we shouldn't get notice/info/debug
# output.
Describe 'logger.sh'
  Include lib/logger.sh

  # First up just make sure we get correct indices
  It 'sevtolvl emerg = 0'
    When run sevtolvl emerg
    The status should equal 0
  End
  It 'sevtolvl alert = 1'
    When run sevtolvl alert
    The status should equal 1
  End
  It 'sevtolvl crit = 2'
    When run sevtolvl crit
    The status should equal 2
  End
  It 'sevtolvl error = 3'
    When run sevtolvl error
    The status should equal 3
  End
  It 'sevtolvl warn = 4'
    When run sevtolvl warn
    The status should equal 4
  End
  It 'sevtolvl notice = 5'
    When run sevtolvl notice
    The status should equal 5
  End
  It 'sevtolvl info = 5'
    When run sevtolvl info
    The status should equal 6
  End
  It 'sevtolvl debug = 7'
    When run sevtolvl debug
    The status should equal 7
  End

  # Default log level is... dunno warn for now?
  It 'sevtolvl = 4'
    When run sevtolvl "$LOG_LEVEL"
    The status should equal 4
  End

  # Default behavior tests
  It 'logs to stderr'
    When call emerg ShellSpec
    The stderr should equal 'emerg: ShellSpec'
  End
  It 'by default ignores notice'
    When call notice ShellSpec
    The stderr should be blank
  End
  It 'by default ignores info'
    When call info ShellSpec
    The stderr should be blank
  End
  It 'by default ignores debug'
    When call debug ShellSpec
    The stderr should be blank
  End
End

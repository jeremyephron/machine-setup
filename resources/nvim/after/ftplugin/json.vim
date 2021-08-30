" JSON File Settings

command Prettify %!if [ $(python3 -c 'import platform; major, minor, patch = platform.python_version_tuple(); print(minor)') -ge 9 ]; then python3 -m json.tool; else python3.9 -m json.tool; fi
command Minify %!if [ $(python3 -c 'import platform; major, minor, patch = platform.python_version_tuple(); print(minor)') -ge 9 ]; then python3 -m json.tool --compact; else python3.9 -m json.tool --compact; fi

#!/bin/bash
# WARNING: This file is not meant to be run directly.

###########################
#     Python Packages     #
###########################

# A set of standard Python packages I like to have globally

echo "-- Updating pip..."
python3 -m pip install --upgrade pip
echo "-- Pip is up to date"

pip_install setuptools Setuptools
pip_install twine Twine
pip_install numpy NumPy
pip_install scikit-learn "Scikit Learn"
pip_install matplotlib Matplotlib
pip_install pandas Pandas
pip_install jupyter "Jupyter Notebook"
pip_install requests Requests
pip_install pillow Pillow
pip_install beautifulsoup4 BeautifulSoup

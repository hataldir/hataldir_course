pip install -r requirements.txt -r requirements-test.txt
python -m unittest discover -s tests/ 
coverage run -m unittest discover -s tests/ 
coverage report --include ui/ui.py

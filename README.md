# Step 1: Clone this project

# Step 2: Create virtual environment
```Terminal
python -m venv venv
```
# Step 3: Activate virtual environment
## On Windows:
```Terminal
venv\Scripts\activate
```
## On macOS/Linux:
```Terminal
source venv/bin/activate
```
# Step 4: Install dependencies
```Terminal
pip install -r requirements.txt
```
# Step 5: Run migrations (if needed)
```Terminal
python manage.py migrate
```
# Step 6: Run development server
```Terminal
python manage.py runserver <portNumber>
```


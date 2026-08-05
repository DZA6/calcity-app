"""
PythonAnywhere WSGI file for CalCity backend.

Deploy instructions:
  1. PA Web tab: create a web app named "calcityapp.pythonanywhere.com"
     (or your chosen subdomain).
  2. Set source directory to /home/MMSantelopevalley/calcity-app
  3. Create venv: mkvirtualenv --python=3.13 calcity-venv
     then: pip install -r requirements.txt
  4. Set this WSGI file's path in the Web tab, paste this file's content.
  5. Set env vars below (Edit in Web tab -> WSGI, or Environment vars).
  6. Run: manage.py migrate && manage.py collectstatic --noinput
  7. Reload.

IMPORTANT: keep the hosts list one-per-line with ','.join([...]) —
a wrapped/pasted line with a stray newline breaks the file (the MMS
site hit exactly this: SyntaxError from a wrapped env line).
"""
import os
import sys

# Source directory of the Django project
project_home = "/home/MMSantelopevalley/calcity-app"
if project_home not in sys.path:
    sys.path.insert(0, project_home)

os.environ["DJANGO_SETTINGS_MODULE"] = "backend.settings"

# --- Environment (values below are PLACEHOLDERS - set real ones) ---
os.environ.setdefault("DJANGO_DEBUG", "False")
os.environ.setdefault(
    "DJANGO_SECRET_KEY", "CHANGE-ME-to-a-long-random-string"
)
os.environ.setdefault(
    "DJANGO_ALLOWED_HOSTS",
    ",".join(
        [
            "calcityapp.pythonanywhere.com",
            "MMSantelopevalley.pythonanywhere.com",
            "www.memorialmediaservices.org",
        ]
    ),
)
# Mobile app origins - use "*" to allow any origin (mobile apps don't
# send Origin headers that CORS checks, so this is typically fine).
os.environ.setdefault("CALCITY_CORS_ORIGINS", "*")
os.environ.setdefault("CALCITY_SSL_REDIRECT", "True")

from django.core.wsgi import get_wsgi_application  # noqa: E402

application = get_wsgi_application()

from django.utils.translation import gettext_lazy as _

PAGE_SIZE_DEFAULT = 20

WEEK_DAYS = (
    ("sunday", _("Sunday")),
    ("monday", _("Monday")),
    ("tuesday", _("Tuesday")),
    ("wednesday", _("Wednesday")),
    ("thursday", _("Thursday")),
    ("friday", _("Friday")),
    ("saturday", _("Saturday")),
)

SAUDI_CITIES = (
    ("riyadh", _("Riyadh")),
    ("jeddah", _("Jeddah")),
    ("mecca", _("Mecca")),
    ("medina", _("Medina")),
    ("dammam", _("Dammam")),
    ("khobar", _("Khobar")),
    ("dhahran", _("Dhahran")),
    ("tabuk", _("Tabuk")),
    ("abha", _("Abha")),
    ("khamis_mushait", _("Khamis Mushait")),
    ("hail", _("Hail")),
    ("najran", _("Najran")),
    ("jubail", _("Jubail")),
    ("yanbu", _("Yanbu")),
    ("taif", _("Taif")),
    ("buraidah", _("Buraidah")),
    ("qatif", _("Qatif")),
    ("hofuf", _("Hofuf")),
    ("jizan", _("Jizan")),
    ("arar", _("Arar")),
)

BRANCH_GENDER_CHOICES = (
    ("men", _("Men Only")),
    ("women", _("Women Only")),
    ("mixed", _("Mixed / Both")),
)

PROVIDER_TYPES = (
    ("gym", _("Gym")),
    # ("trainer", _("Trainer")),
    # ("restaurant", _("Healthy Restaurant")),
    # ("equipment", _("Sports Equipment")),
)
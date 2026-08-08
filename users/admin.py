from django.contrib import admin

from .models import EmailVerificationToken


@admin.register(EmailVerificationToken)
class EmailVerificationTokenAdmin(admin.ModelAdmin):
    list_display = ("user", "is_used", "created_at")
    list_filter = ("is_used",)
    search_fields = ("user__email", "user__username")
    readonly_fields = ("token", "created_at")

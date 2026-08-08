"""Auth serializers — registration, login, email verification."""
import secrets

from django.contrib.auth import authenticate, get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.mail import send_mail
from django.conf import settings
from rest_framework import serializers

from .models import EmailVerificationToken
from .validators import ComplexityValidator, CommonPasswordValidator, MinimumLengthValidator

User = get_user_model()


class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
    username = serializers.CharField(required=True, min_length=3, max_length=150)
    password = serializers.CharField(required=True, write_only=True)

    def validate_email(self, value):
        value = value.lower().strip()
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("An account with this email already exists.")
        return value

    def validate_username(self, value):
        value = value.strip()
        if User.objects.filter(username__iexact=value).exists():
            raise serializers.ValidationError("This username is already taken.")
        if len(value) < 3:
            raise serializers.ValidationError("Username must be at least 3 characters.")
        return value

    def validate_password(self, value):
        # Run all custom validators
        for validator in [
            MinimumLengthValidator(min_length=10),
            ComplexityValidator(),
            CommonPasswordValidator(),
        ]:
            validator.validate(value)
        # Also run Django's built-in validators
        validate_password(value)
        return value

    def create(self, validated_data):
        email = validated_data["email"]
        username = validated_data["username"]
        password = validated_data.pop("password")

        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            is_active=False,  # Must verify email first
        )

        # Create verification token
        token = EmailVerificationToken.objects.create(user=user)

        # Send verification email (non-blocking, logs on failure)
        try:
            verify_url = f"https://calcityapp-MMSantelopevalley.pythonanywhere.com/api/auth/verify-email/?token={token.token}"
            send_mail(
                subject="Verify your CalCity account",
                message=(
                    f"Hi {username},\n\n"
                    f"Please verify your email address by clicking the link below:\n\n"
                    f"{verify_url}\n\n"
                    f"This link expires in 24 hours.\n\n"
                    f"— The CalCity Team"
                ),
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
                fail_silently=True,
            )
        except Exception:
            pass  # Don't block registration if email fails

        return user


class VerifyEmailSerializer(serializers.Serializer):
    token = serializers.CharField(required=True)


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField(required=True)
    password = serializers.CharField(required=True, write_only=True)

    def validate(self, data):
        username = data.get("username", "").strip()
        password = data.get("password", "")

        if not username or not password:
            raise serializers.ValidationError("Username and password are required.")

        # Find user by username or email (Django's authenticate skips inactive users)
        try:
            u = User.objects.get(username=username)
        except User.DoesNotExist:
            try:
                u = User.objects.get(email__iexact=username)
            except User.DoesNotExist:
                raise serializers.ValidationError("Invalid username/email or password.")

        if not u.is_active:
            raise serializers.ValidationError(
                "Please verify your email address before logging in. "
                "Check your inbox for the verification link."
            )

        # Pass request so AxesStandaloneBackend can track IPs
        request = self.context.get("request")
        user = authenticate(request=request, username=u.username, password=password)
        if user is None:
            raise serializers.ValidationError("Invalid username/email or password.")

        data["user"] = user
        return data


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "username", "email", "date_joined"]
        read_only_fields = fields

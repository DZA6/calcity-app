"""Auth views — register, verify email, login, user profile."""
from django.contrib.auth import get_user_model
from django.utils.decorators import method_decorator
from django_ratelimit.decorators import ratelimit
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import EmailVerificationToken
from .serializers import (
    LoginSerializer,
    RegisterSerializer,
    UserSerializer,
    VerifyEmailSerializer,
)

User = get_user_model()


@method_decorator(ratelimit(key="ip", rate="3/h", method="POST", block=False), name="post")
class RegisterView(APIView):
    """Create a new user account. Rate-limited to 3 registrations per hour per IP."""

    permission_classes = [AllowAny]

    def post(self, request):
        # Check rate limit was not exceeded
        was_limited = getattr(request, "limited", False)
        if was_limited:
            return Response(
                {"error": "Too many registration attempts. Please try again later."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        serializer = RegisterSerializer(data=request.data)
        if not serializer.is_valid():
            # Return field-level errors
            errors = {}
            for field, msgs in serializer.errors.items():
                errors[field] = msgs[0] if isinstance(msgs, list) else str(msgs)
            return Response({"errors": errors}, status=status.HTTP_400_BAD_REQUEST)

        user = serializer.save()

        return Response(
            {
                "message": (
                    "Account created! Please check your email "
                    f"({user.email}) for a verification link."
                ),
                "user_id": user.id,
                "username": user.username,
                "email": user.email,
            },
            status=status.HTTP_201_CREATED,
        )


class VerifyEmailView(APIView):
    """Verify email address with token from registration email."""

    permission_classes = [AllowAny]

    def get(self, request):
        serializer = VerifyEmailSerializer(data=request.query_params)
        if not serializer.is_valid():
            return Response(
                {"error": "Invalid or missing verification token."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        token_str = serializer.validated_data["token"]

        try:
            token = EmailVerificationToken.objects.get(token=token_str, is_used=False)
        except EmailVerificationToken.DoesNotExist:
            return Response(
                {"error": "Invalid or already used verification token."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if token.is_expired():
            return Response(
                {"error": "Verification link has expired. Please register again."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Activate user
        user = token.user
        user.is_active = True
        user.save()

        # Mark token as used
        token.is_used = True
        token.save()

        return Response(
            {
                "message": "Email verified successfully! You can now log in.",
                "username": user.username,
                "email": user.email,
            }
        )


class LoginView(APIView):
    """Log in with username/email and password. Returns auth token.

    Rate-limited to 10 attempts per 15 minutes per IP to slow brute force
    (django-axes provides the harder lockout on top).
    """

    permission_classes = [AllowAny]

    @method_decorator(ratelimit(key="ip", rate="10/15m", method="POST", block=False))
    def post(self, request):
        if getattr(request, "limited", False):
            return Response(
                {"error": "Too many login attempts. Please wait a few minutes."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        serializer = LoginSerializer(data=request.data)
        if not serializer.is_valid():
            error = list(serializer.errors.values())[0]
            msg = error[0] if isinstance(error, list) else str(error)
            return Response({"error": msg}, status=status.HTTP_401_UNAUTHORIZED)

        user = serializer.validated_data["user"]

        # Get or create auth token
        token, _ = Token.objects.get_or_create(user=user)

        return Response(
            {
                "token": token.key,
                "user": UserSerializer(user).data,
            }
        )


class LogoutView(APIView):
    """Log out by deleting the auth token."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        request.user.auth_token.delete()
        return Response({"message": "Logged out successfully."})


class UserProfileView(APIView):
    """Get the current user's profile."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

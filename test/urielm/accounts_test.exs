defmodule Urielm.AccountsTest do
  use Urielm.DataCase

  alias Urielm.Accounts

  describe "user registration with handle and display_name" do
    test "register_user/1 creates a user with handle and display_name" do
      attrs = %{
        email: "test@example.com",
        username: "test_user",
        display_name: "Test User",
        password: "password123"
      }

      {:ok, user} = Accounts.register_user(attrs)

      assert user.email == "test@example.com"
      assert user.username == "test_user"
      assert user.display_name == "Test User"
      assert user.email_verified == true
      assert Bcrypt.verify_pass("password123", user.password_hash)
    end

    test "register_user/1 requires email" do
      attrs = %{
        username: "test_user",
        display_name: "Test User",
        password: "password123"
      }

      {:error, changeset} = Accounts.register_user(attrs)
      assert "can't be blank" in errors_on(changeset).email
    end

    test "register_user/1 requires password" do
      attrs = %{
        email: "test@example.com",
        username: "test_user",
        display_name: "Test User"
      }

      {:error, changeset} = Accounts.register_user(attrs)
      assert "can't be blank" in errors_on(changeset).password
    end

    test "register_user/1 requires username" do
      attrs = %{
        email: "test@example.com",
        display_name: "Test User",
        password: "password123"
      }

      {:error, changeset} = Accounts.register_user(attrs)
      assert "can't be blank" in errors_on(changeset).username
    end

    test "register_user/1 requires display_name" do
      attrs = %{
        email: "test@example.com",
        username: "test_user",
        password: "password123"
      }

      {:error, changeset} = Accounts.register_user(attrs)
      assert "can't be blank" in errors_on(changeset).display_name
    end

    test "register_user/1 validates email format" do
      attrs = %{
        email: "invalid_email",
        username: "test_user",
        display_name: "Test User",
        password: "password123"
      }

      {:error, changeset} = Accounts.register_user(attrs)
      assert "must be a valid email" in errors_on(changeset).email
    end

    test "register_user/1 validates password minimum length" do
      attrs = %{
        email: "test@example.com",
        username: "test_user",
        display_name: "Test User",
        password: "short"
      }

      {:error, changeset} = Accounts.register_user(attrs)
      assert "must be at least 8 characters" in errors_on(changeset).password
    end
  end

  describe "handle (username) validation" do
    test "accepts valid handle format: lowercase alphanumeric" do
      attrs = %{
        email: "test@example.com",
        username: "validuser",
        display_name: "Valid User",
        password: "password123"
      }

      {:ok, user} = Accounts.register_user(attrs)
      assert user.username == "validuser"
    end

    test "accepts valid handle format: with underscores" do
      attrs = %{
        email: "test@example.com",
        username: "valid_user_123",
        display_name: "Valid User",
        password: "password123"
      }

      {:ok, user} = Accounts.register_user(attrs)
      assert user.username == "valid_user_123"
    end

    test "accepts valid handle format: with dashes" do
      attrs = %{
        email: "test@example.com",
        username: "valid-user-123",
        display_name: "Valid User",
        password: "password123"
      }

      {:ok, user} = Accounts.register_user(attrs)
      assert user.username == "valid-user-123"
    end

    test "rejects handle with uppercase letters" do
      attrs = %{
        email: "test@example.com",
        username: "InvalidUser",
        display_name: "Invalid User",
        password: "password123"
      }

      {:error, changeset} = Accounts.register_user(attrs)
      assert changeset.errors[:username]
    end

    test "rejects handle with spaces" do
      attrs = %{
        email: "test@example.com",
        username: "invalid user",
        display_name: "Invalid User",
        password: "password123"
      }

      {:error, changeset} = Accounts.register_user(attrs)
      assert changeset.errors[:username]
    end

    test "rejects handle with special characters (except - and _)" do
      attrs = %{
        email: "test@example.com",
        username: "invalid@user",
        display_name: "Invalid User",
        password: "password123"
      }

      {:error, changeset} = Accounts.register_user(attrs)
      assert changeset.errors[:username]
    end

    test "rejects handle shorter than 3 characters" do
      attrs = %{
        email: "test@example.com",
        username: "ab",
        display_name: "Invalid User",
        password: "password123"
      }

      {:error, changeset} = Accounts.register_user(attrs)
      assert changeset.errors[:username]
    end

    test "rejects handle longer than 20 characters" do
      attrs = %{
        email: "test@example.com",
        username: "thisusernameistoolong",
        display_name: "Invalid User",
        password: "password123"
      }

      {:error, changeset} = Accounts.register_user(attrs)
      assert changeset.errors[:username]
    end

    test "rejects handle with leading dash" do
      attrs = %{
        email: "test@example.com",
        username: "-invalid",
        display_name: "Invalid User",
        password: "password123"
      }

      {:error, changeset} = Accounts.register_user(attrs)
      assert changeset.errors[:username]
    end

    test "rejects handle with trailing dash" do
      attrs = %{
        email: "test@example.com",
        username: "invalid-",
        display_name: "Invalid User",
        password: "password123"
      }

      {:error, changeset} = Accounts.register_user(attrs)
      assert changeset.errors[:username]
    end

    test "rejects handle with consecutive dashes" do
      attrs = %{
        email: "test@example.com",
        username: "invalid--user",
        display_name: "Invalid User",
        password: "password123"
      }

      {:error, changeset} = Accounts.register_user(attrs)
      assert changeset.errors[:username]
    end

    test "requires unique handle" do
      attrs = %{
        email: "test1@example.com",
        username: "uniqueuser",
        display_name: "Test User 1",
        password: "password123"
      }

      {:ok, _user1} = Accounts.register_user(attrs)

      duplicate_attrs = %{
        email: "test2@example.com",
        username: "uniqueuser",
        display_name: "Test User 2",
        password: "password123"
      }

      {:error, changeset} = Accounts.register_user(duplicate_attrs)
      assert "has already been taken" in errors_on(changeset).username
    end
  end

  describe "display_name validation" do
    test "accepts display_name with spaces" do
      attrs = %{
        email: "test@example.com",
        username: "testuser",
        display_name: "John Doe",
        password: "password123"
      }

      {:ok, user} = Accounts.register_user(attrs)
      assert user.display_name == "John Doe"
    end

    test "accepts display_name with emojis" do
      attrs = %{
        email: "test@example.com",
        username: "testuser",
        display_name: "John 🚀",
        password: "password123"
      }

      {:ok, user} = Accounts.register_user(attrs)
      assert user.display_name == "John 🚀"
    end

    test "accepts display_name with various characters" do
      attrs = %{
        email: "test@example.com",
        username: "testuser",
        display_name: "John O'Brien-Smith",
        password: "password123"
      }

      {:ok, user} = Accounts.register_user(attrs)
      assert user.display_name == "John O'Brien-Smith"
    end
  end

  describe "get_user_by_username/1" do
    test "returns user by username" do
      attrs = %{
        email: "test@example.com",
        username: "testuser",
        display_name: "Test User",
        password: "password123"
      }

      {:ok, created_user} = Accounts.register_user(attrs)
      found_user = Accounts.get_user_by_username("testuser")

      assert found_user.id == created_user.id
      assert found_user.username == "testuser"
    end

    test "returns nil for non-existent username" do
      user = Accounts.get_user_by_username("nonexistent")
      assert is_nil(user)
    end

    test "is case-insensitive (case-folded lookup)" do
      attrs = %{
        email: "test@example.com",
        username: "testuser",
        display_name: "Test User",
        password: "password123"
      }

      {:ok, created_user} = Accounts.register_user(attrs)

      # Should find with different case (case-insensitive lookup)
      user = Accounts.get_user_by_username("TestUser")
      assert user.id == created_user.id
      assert user.username == "testuser"
    end
  end

  describe "authenticate_user/2" do
    test "authenticates with valid email and password" do
      attrs = %{
        email: "test@example.com",
        username: "testuser",
        display_name: "Test User",
        password: "password123"
      }

      {:ok, _user} = Accounts.register_user(attrs)

      {:ok, authenticated_user} = Accounts.authenticate_user("test@example.com", "password123")
      assert authenticated_user.email == "test@example.com"
      assert authenticated_user.username == "testuser"
      assert authenticated_user.display_name == "Test User"
    end

    test "rejects invalid password" do
      attrs = %{
        email: "test@example.com",
        username: "testuser",
        display_name: "Test User",
        password: "password123"
      }

      {:ok, _user} = Accounts.register_user(attrs)

      {:error, :invalid_credentials} =
        Accounts.authenticate_user("test@example.com", "wrongpassword")
    end

    test "rejects non-existent email" do
      {:error, :invalid_credentials} =
        Accounts.authenticate_user("nonexistent@example.com", "password123")
    end
  end

  describe "User schema validations" do
    test "password is hashed and stored in password_hash" do
      attrs = %{
        email: "test@example.com",
        username: "testuser",
        display_name: "Test User",
        password: "password123"
      }

      {:ok, user} = Accounts.register_user(attrs)

      # Password hash should be set
      assert user.password_hash != nil
      # Should be able to verify password
      assert Bcrypt.verify_pass("password123", user.password_hash)
    end

    test "email_verified is set to true for email/password signup" do
      attrs = %{
        email: "test@example.com",
        username: "testuser",
        display_name: "Test User",
        password: "password123"
      }

      {:ok, user} = Accounts.register_user(attrs)
      assert user.email_verified == true
    end
  end
end

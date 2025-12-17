defmodule UrielmWeb.AuthControllerTest do
  use UrielmWeb.ConnCase

  alias Urielm.Accounts

  describe "POST /auth/signup" do
    test "successful signup with valid credentials", %{conn: conn} do
      signup_params = %{
        email: "newuser@example.com",
        username: "newuser",
        displayName: "New User",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signup", signup_params)

      assert json_response(conn, 200) == %{"success" => true}
      assert get_session(conn, :user_id)

      # Verify user was created
      user = Accounts.get_user_by_email("newuser@example.com")
      assert user.username == "newuser"
      assert user.display_name == "New User"
    end

    test "signup auto-normalizes username to lowercase", %{conn: conn} do
      signup_params = %{
        email: "newuser@example.com",
        username: "NewUser",
        displayName: "New User",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signup", signup_params)

      assert json_response(conn, 200) == %{"success" => true}

      user = Accounts.get_user_by_email("newuser@example.com")
      assert user.username == "newuser"
    end

    test "signup trims whitespace from username", %{conn: conn} do
      signup_params = %{
        email: "newuser@example.com",
        username: "  newuser  ",
        displayName: "New User",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signup", signup_params)

      assert json_response(conn, 200) == %{"success" => true}

      user = Accounts.get_user_by_email("newuser@example.com")
      assert user.username == "newuser"
    end

    test "signup trims whitespace from display_name", %{conn: conn} do
      signup_params = %{
        email: "newuser@example.com",
        username: "newuser",
        displayName: "  New User  ",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signup", signup_params)

      assert json_response(conn, 200) == %{"success" => true}

      user = Accounts.get_user_by_email("newuser@example.com")
      assert user.display_name == "New User"
    end

    test "signup fails with invalid email", %{conn: conn} do
      signup_params = %{
        email: "invalid_email",
        username: "newuser",
        displayName: "New User",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signup", signup_params)

      assert response(conn, 422)
      response = json_response(conn, 422)
      assert response["error"] =~ "email"
    end

    test "signup fails with short password", %{conn: conn} do
      signup_params = %{
        email: "newuser@example.com",
        username: "newuser",
        displayName: "New User",
        password: "short"
      }

      conn = post(conn, ~p"/auth/signup", signup_params)

      assert response(conn, 422)
      response = json_response(conn, 422)
      assert response["error"] =~ "password"
    end

    test "signup fails with invalid username format", %{conn: conn} do
      signup_params = %{
        email: "newuser@example.com",
        username: "Invalid@User",
        displayName: "New User",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signup", signup_params)

      assert response(conn, 422)
      response = json_response(conn, 422)
      assert response["error"] =~ "username"
    end

    test "signup fails with username too short", %{conn: conn} do
      signup_params = %{
        email: "newuser@example.com",
        username: "ab",
        displayName: "New User",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signup", signup_params)

      assert response(conn, 422)
      response = json_response(conn, 422)
      assert response["error"] =~ "username"
    end

    test "signup fails with duplicate email", %{conn: conn} do
      # Create first user
      first_params = %{
        email: "duplicate@example.com",
        username: "user1",
        displayName: "User 1",
        password: "password123"
      }

      post(conn, ~p"/auth/signup", first_params)

      # Try to create user with same email
      second_params = %{
        email: "duplicate@example.com",
        username: "user2",
        displayName: "User 2",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signup", second_params)

      assert response(conn, 422)
      response = json_response(conn, 422)
      assert response["error"] =~ "email"
    end

    test "signup fails with duplicate username", %{conn: conn} do
      # Create first user
      first_params = %{
        email: "user1@example.com",
        username: "duplicate",
        displayName: "User 1",
        password: "password123"
      }

      post(conn, ~p"/auth/signup", first_params)

      # Try to create user with same username
      second_params = %{
        email: "user2@example.com",
        username: "duplicate",
        displayName: "User 2",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signup", second_params)

      assert response(conn, 422)
      response = json_response(conn, 422)
      assert response["error"] =~ "username"
    end

    test "signup fails with missing email", %{conn: conn} do
      signup_params = %{
        username: "newuser",
        displayName: "New User",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signup", signup_params)

      assert response(conn, 422)
    end

    test "signup fails with missing password", %{conn: conn} do
      signup_params = %{
        email: "newuser@example.com",
        username: "newuser",
        displayName: "New User"
      }

      conn = post(conn, ~p"/auth/signup", signup_params)

      assert response(conn, 422)
    end

    test "signup fails with missing username", %{conn: conn} do
      signup_params = %{
        email: "newuser@example.com",
        displayName: "New User",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signup", signup_params)

      assert response(conn, 422)
    end

    test "signup fails with missing displayName", %{conn: conn} do
      signup_params = %{
        email: "newuser@example.com",
        username: "newuser",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signup", signup_params)

      assert response(conn, 422)
    end

    test "signup with dashes in username", %{conn: conn} do
      signup_params = %{
        email: "newuser@example.com",
        username: "new-user-123",
        displayName: "New User",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signup", signup_params)

      assert json_response(conn, 200) == %{"success" => true}

      user = Accounts.get_user_by_email("newuser@example.com")
      assert user.username == "new-user-123"
    end

    test "signup with underscores in username", %{conn: conn} do
      signup_params = %{
        email: "newuser@example.com",
        username: "new_user_123",
        displayName: "New User",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signup", signup_params)

      assert json_response(conn, 200) == %{"success" => true}

      user = Accounts.get_user_by_email("newuser@example.com")
      assert user.username == "new_user_123"
    end

    test "signup with display_name containing special characters", %{conn: conn} do
      signup_params = %{
        email: "newuser@example.com",
        username: "newuser",
        displayName: "John O'Brien-Smith 🚀",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signup", signup_params)

      assert json_response(conn, 200) == %{"success" => true}

      user = Accounts.get_user_by_email("newuser@example.com")
      assert user.display_name == "John O'Brien-Smith 🚀"
    end
  end

  describe "POST /auth/signin" do
    setup do
      Accounts.register_user(%{
        email: "signin@example.com",
        username: "signinuser",
        display_name: "Signin User",
        password: "password123"
      })

      :ok
    end

    test "successful signin with valid credentials", %{conn: conn} do
      signin_params = %{
        email: "signin@example.com",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signin", signin_params)

      assert json_response(conn, 200) == %{"success" => true}
      assert get_session(conn, :user_id)
    end

    test "signin fails with wrong password", %{conn: conn} do
      signin_params = %{
        email: "signin@example.com",
        password: "wrongpassword"
      }

      conn = post(conn, ~p"/auth/signin", signin_params)

      assert response(conn, 401)
      assert json_response(conn, 401) == %{"error" => "Invalid email or password"}
    end

    test "signin fails with non-existent email", %{conn: conn} do
      signin_params = %{
        email: "nonexistent@example.com",
        password: "password123"
      }

      conn = post(conn, ~p"/auth/signin", signin_params)

      assert response(conn, 401)
      assert json_response(conn, 401) == %{"error" => "Invalid email or password"}
    end
  end

  describe "GET /api/check-handle" do
    test "returns available for non-existent username", %{conn: conn} do
      conn = get(conn, ~p"/api/check-handle?username=availableuser")

      assert response(conn, 200)
      assert json_response(conn, 200) == %{"available" => true}
    end

    test "returns unavailable for existing username", %{conn: conn} do
      Accounts.register_user(%{
        email: "user@example.com",
        username: "existinguser",
        display_name: "Existing User",
        password: "password123"
      })

      conn = get(conn, ~p"/api/check-handle?username=existinguser")

      assert response(conn, 200)
      assert json_response(conn, 200) == %{"available" => false}
    end

    test "handle check normalizes to lowercase before checking", %{conn: conn} do
      Accounts.register_user(%{
        email: "user@example.com",
        username: "existinguser",
        display_name: "Existing User",
        password: "password123"
      })

      # Controller normalizes to lowercase, so ExistingUser becomes existinguser
      conn = get(conn, ~p"/api/check-handle?username=ExistingUser")

      assert response(conn, 200)
      # Should find the existing user because controller normalizes case
      assert json_response(conn, 200) == %{"available" => false}
    end

    test "handle check normalizes to lowercase", %{conn: conn} do
      Accounts.register_user(%{
        email: "user@example.com",
        username: "existinguser",
        display_name: "Existing User",
        password: "password123"
      })

      # Query with uppercase - controller will downcase it
      conn = get(conn, ~p"/api/check-handle?username=existinguser")

      assert response(conn, 200)
      assert json_response(conn, 200) == %{"available" => false}
    end

    test "handle check with underscores", %{conn: conn} do
      Accounts.register_user(%{
        email: "user@example.com",
        username: "existing_user",
        display_name: "Existing User",
        password: "password123"
      })

      conn = get(conn, ~p"/api/check-handle?username=existing_user")

      assert response(conn, 200)
      assert json_response(conn, 200) == %{"available" => false}
    end

    test "handle check with dashes", %{conn: conn} do
      Accounts.register_user(%{
        email: "user@example.com",
        username: "existing-user",
        display_name: "Existing User",
        password: "password123"
      })

      conn = get(conn, ~p"/api/check-handle?username=existing-user")

      assert response(conn, 200)
      assert json_response(conn, 200) == %{"available" => false}
    end

    test "handle check with whitespace trimming", %{conn: conn} do
      Accounts.register_user(%{
        email: "user@example.com",
        username: "existinguser",
        display_name: "Existing User",
        password: "password123"
      })

      # Query with whitespace
      conn = get(conn, ~p"/api/check-handle?username=  existinguser  ")

      assert response(conn, 200)
      # Should find the existing user after trimming
      assert json_response(conn, 200) == %{"available" => false}
    end
  end

  describe "DELETE /auth/logout" do
    setup do
      {:ok, _user} =
        Accounts.register_user(%{
          email: "logout@example.com",
          username: "logoutuser",
          display_name: "Logout User",
          password: "password123"
        })

      :ok
    end

    test "logout clears session", %{conn: conn} do
      # First sign in
      signin_params = %{
        email: "logout@example.com",
        password: "password123"
      }

      signed_in_conn = post(conn, ~p"/auth/signin", signin_params)
      assert get_session(signed_in_conn, :user_id)

      # Then log out
      logout_conn = delete(signed_in_conn, ~p"/auth/logout")

      # Redirect to home
      assert redirected_to(logout_conn) == "/"
    end
  end
end

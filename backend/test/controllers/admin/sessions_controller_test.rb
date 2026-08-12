require "test_helper"

class Admin::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "管理者ログイン画面をadmin用認証デザインで表示する" do
    get new_admin_account_session_path

    assert_response :success
    assert_select "body.authentication-page--admin", count: 1
    assert_select 'link[rel="stylesheet"][href*="authentication"]', count: 1
    assert_select ".authentication-role-label", text: /運営管理画面/
    assert_select ".authentication-card h2", text: "運営管理者ログイン"
    assert_select "form.authentication-form[action=?]", admin_account_session_path
    assert_select "input#admin_email[required][autocomplete='username']", count: 1
    assert_select "input#admin_password[required][autocomplete='current-password']", count: 1
    assert_select ".authentication-submit[value='ログイン']", count: 1
    assert_select "style", count: 0
  end

  test "管理者ログイン画面のエラーをalertとして表示する" do
    post admin_account_session_path, params: {
      admin_account: {
        email: "unknown-admin@example.com",
        password: "invalid-password"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".authentication-flash--alert[role='alert']", count: 1
  end
end

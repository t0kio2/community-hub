require "test_helper"

class Tenant::BaseControllerTest < ActiveSupport::TestCase
  test "テナント取得は値を設定するだけでリダイレクトしない" do
    controller = Tenant::BaseController.new
    member = Struct.new(:tenant).new(nil)
    redirect_called = false
    controller.define_singleton_method(:current_tenant_member) { member }
    controller.define_singleton_method(:redirect_to) { |*| redirect_called = true }

    controller.send(:set_current_tenant)

    assert_nil controller.instance_variable_get(:@tenant)
    assert_not redirect_called
  end

  test "テナント必須チェックは未設定時にホームへ戻す" do
    controller = Tenant::BaseController.new
    redirect_options = nil
    controller.define_singleton_method(:tenant_root_path) { "/tenant" }
    controller.define_singleton_method(:redirect_to) do |*args, **options|
      redirect_options = [ args, options ]
    end

    controller.send(:require_current_tenant!)

    assert_equal [ [ "/tenant" ], { alert: "組織情報がありません" } ], redirect_options
  end

  test "ホームはテナント必須チェックを実行しない" do
    filters = Tenant::HomeController._process_action_callbacks.map(&:filter)

    assert_not_includes filters, :require_current_tenant!
  end

  test "業務画面はテナント必須チェックを実行する" do
    controllers = [
      Tenant::JobsController,
      Tenant::StaysController,
      Tenant::LocationsController,
      Tenant::OrganizationsController
    ]

    controllers.each do |controller_class|
      filters = controller_class._process_action_callbacks.map(&:filter)
      assert_includes filters, :require_current_tenant!
    end
  end
end

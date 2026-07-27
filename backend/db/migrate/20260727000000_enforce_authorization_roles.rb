class EnforceAuthorizationRoles < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO admins (account_id, role, status, created_at, updated_at)
      SELECT accounts.id, 'super_admin', 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM accounts
      LEFT JOIN admins ON admins.account_id = accounts.id
      WHERE accounts.account_type = 'admin'
        AND admins.id IS NULL
    SQL

    execute <<~SQL
      UPDATE tenant_members
      SET role = 'staff'
      WHERE role IS NULL OR role NOT IN ('owner', 'staff')
    SQL

    execute <<~SQL
      UPDATE admins
      SET role = 'operator'
      WHERE role IS NULL OR role NOT IN ('super_admin', 'operator')
    SQL

    execute "UPDATE tenant_members SET status = 'active' WHERE status IS NULL"
    execute "UPDATE admins SET status = 'active' WHERE status IS NULL"

    execute <<~SQL
      UPDATE admins
      SET role = 'super_admin'
      WHERE id = (
        SELECT id
        FROM admins
        WHERE status = 'active'
        ORDER BY id
        LIMIT 1
      )
      AND NOT EXISTS (
        SELECT 1
        FROM admins
        WHERE role = 'super_admin' AND status = 'active'
      )
    SQL

    change_column_null :tenant_members, :role, false
    change_column_null :tenant_members, :status, false
    change_column_null :admins, :role, false
    change_column_null :admins, :status, false

    add_check_constraint :tenant_members,
                         "role IN ('owner', 'staff')",
                         name: "tenant_members_role_check"
    add_check_constraint :admins,
                         "role IN ('super_admin', 'operator')",
                         name: "admins_role_check"
  end

  def down
    remove_check_constraint :admins, name: "admins_role_check"
    remove_check_constraint :tenant_members, name: "tenant_members_role_check"

    change_column_null :admins, :status, true
    change_column_null :admins, :role, true
    change_column_null :tenant_members, :status, true
    change_column_null :tenant_members, :role, true
  end
end

class ChangeIntToUuidInDevices < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    begin
      max_id = Devices::Device.select("max(id) as max_id").to_a.last[:max_id] || 0
      if max_id > 0
        batch_size = 100_000
        (0..max_id).step(batch_size).each do |from_id|
          to_id = from_id + batch_size
          ActiveRecord::Base.transaction do
            execute <<-SQL
            UPDATE devices
            SET
              app_version_id = NULL
            WHERE id BETWEEN #{from_id} AND #{to_id}
            SQL
          end
        end
      end
    rescue => e
      puts e
    end

    change_column :devices, :app_version_id, "UUID USING CAST(LPAD(TO_HEX(app_version_id), 32, '0') AS UUID)"
  end
end

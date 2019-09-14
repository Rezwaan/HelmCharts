class AddCompanyTable < ActiveRecord::Migration[5.2]
  def change
    create_table :companies, id: :uuid do |t|
      t.string :registration_number

      t.timestamps
    end
  end
end

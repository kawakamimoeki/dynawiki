rails db:migrate
rails runner "Language.create([{ name: :en }, { name: :ja }])"

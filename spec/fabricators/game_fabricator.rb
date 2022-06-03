Fabricator(:game) do
  name 'Half-Life 3'
  appid '12312100'
  tier %w[native platinum gold silver bronze borked unknown].sample
  trending_tier  %w[native platinum gold silver bronze borked unknown].sample
  created_at Time.zone.now
  updated_at Time.zone.now
end

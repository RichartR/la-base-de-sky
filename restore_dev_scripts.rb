require 'fileutils'

RESTORE_MAP = {
  "Data/Scripts_Backup_Dev/009_Turbo.rb" => "Data/Scripts/043_Utilities/009_Turbo.rb",
  "Data/Scripts_Backup_Dev/010_Fancy Camera.rb" => "Data/Scripts/025_Overworld/010_Fancy Camera.rb",
  "Data/Scripts_Backup_Dev/003_Sprite_Character.rb" => "Data/Scripts/009_Sprites/003_Sprite_Character.rb",
  "Data/Scripts_Backup_Dev/001_TilemapRenderer.rb" => "Data/Scripts/010_Map renderer/001_TilemapRenderer.rb"
}

RESTORE_MAP.each do |backup_file, target_file|
  if File.exist?(backup_file)
    FileUtils.cp(backup_file, target_file)
    puts "Restored: #{backup_file} -> #{target_file} (#{File.size(target_file)} bytes)"
  else
    puts "Backup not found: #{backup_file}"
  end
end
puts "Restoration to dev complete."

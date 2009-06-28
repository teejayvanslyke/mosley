require 'typus'

if Typus.testing?
  Typus::Configuration.options[:config_folder] = 'vendor/plugins/typus/test/config/working'
end

##
# Do not Typus.enable or Typus.generate if we are running a generator.
#

scripts = %w( script/generate script/destroy )

unless scripts.include?($0)
  Typus.enable
  Typus.generator unless Typus.testing?
end
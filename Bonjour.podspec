Pod::Spec.new do |s|
  s.name = "Bonjour"
  s.version = "0.0.1"

  s.summary = "Bonjour"
  s.homepage = "https://github.com/eugenebokhan/Bonjour"

  s.author = {
    "Eugene Bokhan" => "eugenebokhan@protonmail.com"
  }

  s.ios.deployment_target = "12.0"
  s.osx.deployment_target = '10.14'

  s.source = {
    :git => "https://github.com/eugenebokhan/Bonjour.git",
    :tag => "#{s.version}"
  }
  s.source_files = "Sources/**/*.{swift}"

  s.swift_version = "5.2"
end

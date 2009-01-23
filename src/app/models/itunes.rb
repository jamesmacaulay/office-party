class Itunes
  def self.app
    @@app ||= RbItunes::App.new
  end
end

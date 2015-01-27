class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner
end

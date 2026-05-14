class Project < ApplicationRecord
  STATUSES = %w[active archived].freeze

  belongs_to :owner, class_name: "User"
  has_many :project_memberships, dependent: :destroy
  has_many :members, through: :project_memberships, source: :user
  has_many :tasks, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :status, inclusion: { in: STATUSES }

  before_validation :generate_slug, on: :create
  after_create_commit :create_owner_membership

  def to_param
    slug
  end

  private

  def generate_slug
    return if name.blank?

    base = name.parameterize
    base = "project" if base.blank?
    candidate = base
    counter = 2

    while Project.exists?(slug: candidate)
      candidate = "#{base}-#{counter}"
      counter += 1
    end

    self.slug = candidate
  end

  def create_owner_membership
    project_memberships.create!(user: owner, role: "owner")
  end
end

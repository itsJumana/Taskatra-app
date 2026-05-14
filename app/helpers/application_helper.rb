module ApplicationHelper
  PRIORITY_BADGE_CLASSES = {
    0 => "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300",           # urgent
    1 => "bg-orange-100 dark:bg-orange-900/30 text-orange-700 dark:text-orange-300", # high
    2 => "bg-zinc-100 dark:bg-zinc-800 text-zinc-700 dark:text-zinc-300",           # medium
    3 => "bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300"          # low
  }.freeze

  def priority_badge_classes(priority)
    PRIORITY_BADGE_CLASSES[priority.to_i] || PRIORITY_BADGE_CLASSES[2]
  end

  def priority_label(priority)
    Task::PRIORITIES.key(priority.to_i).to_s.capitalize.presence || "Medium"
  end
end

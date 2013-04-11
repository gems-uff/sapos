class Allocation < ActiveRecord::Base
  belongs_to :course_class

  validates :day, :inclusion => {:in => I18n.translate("date.day_names")}, :presence => true
  validates :course_class, :presence => true
  validates :start_time, :presence => true
  validates :end_time, :presence => true
  validate :start_end_time_validation
  validate :scheduling_conflict_validation

  before_validation :standardize_times

  private
  def standardize_times
    standard_date = Time.parse('2000/01/01')
    self.start_time = (Time.parse(standard_date.strftime("%Y/%m/%d") + start_time.strftime(" %H:%M:%S")) + self.start_time.utc_offset).utc
    self.end_time = (Time.parse(standard_date.strftime("%Y/%m/%d") + end_time.strftime(" %H:%M:%S")) + self.end_time.utc_offset).utc
  end

  def start_end_time_validation
    if !self.start_time.blank? and !self.end_time.blank? and self.end_time <= self.start_time
      errors.add(:start_time, I18n.t("activerecord.errors.models.allocation.end_time_before_start_time"))
    end
  end

  def scheduling_conflict_validation
    allocations = Allocation.where(:course_class_id => self.course_class, :day => self.day)
    puts "allocations #{allocations.inspect}"

    if allocations and !self.start_time.blank? and !self.end_time.blank?
      puts "dentro do if"
      puts
      allocations.each do |allocation|
        if allocation.id != self.id
          puts "self #{self.inspect}"
          puts "allocation #{allocation.inspect}"
          puts
          if self.start_time.between?(allocation.start_time, allocation.end_time)
            puts "vou colocar erro no start time!"

            errors.add(:start_time, I18n.t("activerecord.errors.models.allocation.scheduling_conflict"))
            puts "coloquei erro no start time!"
            break
          elsif self.end_time.between?(allocation.start_time, allocation.end_time)
            puts "vou colocar erro no end time!"
            errors.add(:end_time, I18n.t("activerecord.errors.models.allocation.scheduling_conflict"))
            puts "coloquei erro no end time!"
            break
          end
        end
      end
    end
  end

end

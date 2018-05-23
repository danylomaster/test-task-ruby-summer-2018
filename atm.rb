require 'yaml'

config = YAML.load_file(ARGV.first || 'config.yml')

class ATM
  attr_accessor :users, :banknotes, :current_user, :user_choise
  
  def initialize
     self.users = [] # on object creation initialize this to an array
     self.banknotes = []
  end
  
  def reconfigure (config)
    config['accounts'].each do |key, value|
      user = User.new
      user.account_id = key
      value.each do |k, v|
        user.name = v if k == 'name'
        user.password = v if k == 'password'
        user.balance = v if k == 'balance'
      end
      self.users.push(user)
    end
    config['banknotes'].each do |key, value|
      banknote = Banknote.new
      banknote.note = key
      banknote.ammount = value
      self.banknotes.push(banknote)
    end    
  end
  
  def total_cash_in_atm
    result = 0
    self.banknotes.each do |note|
      result += note.total
    end
    result
  end
  
  def user_account_exists? (account)
    self.users.map(&:account_id).include? account
  end
  
  def select_current_user(account)
    self.current_user = self.users.select{|x| x.account_id == account }.first
  end
  
  def display_choises
    puts ""
    puts "Please Choose From the Following Options:"
    puts " 1. Display Balance"
    puts " 2. Withdraw"
    puts " 3. Log Out"
    puts ""
  end
  
  def ask_user_choise
    self.display_choises
    self.user_choise = Integer(gets.chomp) rescue 0
    while self.user_choise <= 0 do
      puts "Invalid Choice"
      self.ask_user_choise
    end
  end
  
  def ask_user_withdraw
    puts "Enter Amount You Wish to Withdraw:"
    err = -1
    while err != 0 do
      withdraw_ammount = Integer(gets.chomp) rescue 0
      
      if withdraw_ammount > self.total_cash_in_atm * 2
        err = 1
      elsif (withdraw_ammount > self.total_cash_in_atm) && (withdraw_ammount <= self.total_cash_in_atm * 2)
        err = 2
      elsif self.can_widthraw?(withdraw_ammount) == false
        err = 3
      elsif self.current_user.balance - withdraw_ammount  < 0
        err = 4
      else
        err = 0
      end
      
      case err
      when 1
        puts "ERROR: INSUFFICIENT FUNDS!! PLEASE ENTER A DIFFERENT AMOUNT:"
      when 2
        puts "ERROR: THE MAXIMUM AMOUNT AVAILABLE IN THIS ATM IS ₴#{self.total_cash_in_atm}. PLEASE ENTER A DIFFERENT AMOUNT:"
      when 3
        puts "ERROR: THE AMOUNT YOU REQUESTED CANNOT BE COMPOSED FROM BILLS AVAILABLE IN THIS ATM. PLEASE ENTER A DIFFERENT AMOUNT:"
      when 4
        puts "ERROR: INSUFFICIENT FUNDS IN YOUR BALANCE!! PLEASE ENTER A DIFFERENT AMOUNT:"
      end

    end
    
    if err == 0
      self.current_user.change_balance(withdraw_ammount)
      self.current_user.display_new_balance
    end

  end  
  
  def user_logout
    self.current_user = nil
    self.user_choise = nil
  end
  
  def can_widthraw?(ammount)
    total = 0
    calculated_banknotes = Marshal.load( Marshal.dump(self.banknotes) )
    calculated_banknotes.each do |x|
      while (ammount.divmod(x.note).first > 0) && (x.ammount > 0)
        ammount -= x.note
        x.ammount -= 1
      end
    end
    self.banknotes = Marshal.load( Marshal.dump(calculated_banknotes) ) if ammount == 0
    ammount == 0
  end

end

class User
  attr_accessor :account_id, :name, :password, :balance
  
  def ask_user_account_id
    puts "Please Enter Your Account Number:"    
    self.account_id = Integer(gets.chomp) rescue 0
  end
  
  def ask_user_password
    puts "Enter Your Password:"    
    self.password = gets.chomp
  end  
  
  def correct_password?(password)
    self.password == password
  end
  
  def display_greeting
    puts ""
    puts "Hello, #{self.name}!"
  end
  
  def display_good_bye
    puts ""
    puts "#{self.name}, Thank You For Using Our ATM. Good-Bye!"
    puts ""
  end
  
  def display_balance
    puts ""
    puts "Your Current Balance is ₴#{self.balance}"
  end
  
  def display_new_balance
    puts ""
    puts "Your New Balance is ₴#{self.balance}"
  end

  def change_balance (ammount)
    self.balance -= ammount
  end
  
end

class Banknote
  attr_accessor :note, :ammount
  
  def total
    self.note.to_i * self.ammount.to_i
  end
end


atm = ATM.new
atm.reconfigure(config)

while atm.current_user.nil? do

person = User.new
person.ask_user_account_id

while person.account_id <= 0 || !atm.user_account_exists?(person.account_id)  do
  puts "Invalid Input !!!"
  person.ask_user_account_id
end

atm.select_current_user(person.account_id)

person.ask_user_password

while !atm.current_user.correct_password?(person.password)  do
  puts "Invalid Password !!!"
  person.ask_user_password
end

atm.current_user.display_greeting

while atm.user_choise != 3 do
  atm.ask_user_choise

  case atm.user_choise
  when 1
    atm.current_user.display_balance
  when 2
    atm.ask_user_withdraw
  when 3
    atm.current_user.display_good_bye
    atm.user_logout
    break
  else
    puts "Invalid Choice"
  end
end

end

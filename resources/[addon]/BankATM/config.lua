config = {}

config.notifyName = "Fleeca Bank"
config.notifyDesc = "ATM Machine"
config.notifyIcon = "CHAR_BANK_FLEECA"

config.atmModels = {
	"prop_atm_01",
	"prop_atm_02",
	"prop_atm_03",
	"prop_fleeca_atm"
}

config.msg_deposit1 = "Vous n'avez pas cette somme."
config.msg_deposit2 = {"Vous avez déposer $","sur votre carte."}

config.msg_withdraw1 = "Vous n'avez pas cette somme."
config.msg_withdraw2 = {"Vous avez retirer $","de votre carte."}

config.atm_lang = {
	welcome_title = "Welcome to",
	title="FL<b>EE</b>CA BANK",
	insert_card="Insert a card",

	balance="Balance",
	withdraw="Withdrawal",
	deposit="Deposit",
	exit="Exit",
	back="Back",
	custom_input="Custom Input",
	msg_balance="Your Balance",
	
	msg_deposit="How much money you want to deposit?",
	msg_withdraw="How much money you want to withdraw?",

	msg_thanks = "Thanks for using our services",
	msg_soon = "See you soon!"

}

-- If you want to enable OX Target, you can set this to true
config.ox_target = true 
config.ox_target_name = "Open ATM"
eBank = {
    Brand = {
        Enabled  = true,
        Id       = "fleeca",
        Name     = "Fleeca Bank",
        Tagline  = "Votre partenaire financier",
        -- Path relative to nui://null-cache/images/  (résolu par cacheImg côté React)
        -- Laisse vide ("") pour utiliser l'icône fallback
        Logo     = "shopui/brands/fleeca-bank.webp",
        BgColor  = "#0c1f17",
        Accent   = "#10b981", -- couleur principale de la banque (override le primaryColor global)
    },
    Money = {
        Active = true,
        AccountName = 'cash', 
    },
    Bank = {
        Active = true,
        AccountName = 'bank',
    },
    Virement = {
        Active = true,
    },
    History = {
        Active = true,
        MinimumTransactionPrice = 1,
    },
    Credit = {
        Active = true,
        MaxActiveLoans = 1,
        InterestRate = 0.05,          -- 5% interest
        MaxAmount = 500000,
        MinAmount = 1000,
        MaxDurationWeeks = 12,
        MinDurationWeeks = 1,
        Installments = {4, 8, 12},    -- available installment counts
        MissedPaymentPenalty = 0.02,  -- 2% penalty on missed payment
        AutoPayment = true,           -- auto-deduct from bank on due date
    },
    Categories = {
        deposit    = { label = "Dépôt",           icon = "deposit" },
        withdraw   = { label = "Retrait",          icon = "withdraw" },
        transfer   = { label = "Virement",         icon = "transfer" },
        purchase   = { label = "Achat",            icon = "purchase" },
        salary     = { label = "Salaire",          icon = "salary" },
        fine       = { label = "Amende",           icon = "fine" },
        loan       = { label = "Crédit",           icon = "loan" },
        repayment  = { label = "Remboursement",    icon = "repayment" },
        other      = { label = "Autre",            icon = "other" },
    },
    CardConfig = {
        price = 250,
        itemName = 'bank_card',
    },
}
export interface RuleItem {
  text: string;
  type: 'rule' | 'example' | 'warning' | 'forbidden' | 'allowed' | 'sanction' | 'note' | 'sub';
}

export interface RuleSection {
  id: string;
  title: string;
  icon: string;
  color: string;
  intro?: string;
  rules: RuleItem[];
  subsections?: RuleSubsection[];
}

export interface RuleSubsection {
  id: string;
  title: string;
  intro?: string;
  rules: RuleItem[];
}

export interface RulesCategory {
  id: string;
  label: string;
  icon: string;
  color: string;
  sections: RuleSection[];
}

import React, { useState, useEffect, useRef, useMemo, useCallback } from 'react';
import {
  X, Search, BookOpen, ShoppingBag, Monitor, Theater,
  Shield, Siren, HeartPulse, Building2, Skull, Banknote,
  FlaskConical, Users, ChevronRight,
  AlertTriangle, CheckCircle2, XCircle, Info, FileText,
  Scroll, Video, HeartHandshake, Sword, MapPin
} from 'lucide-react';
import { generateAccentVars } from '@/utils/accentColors';
import { RulesCategory, RuleSection, RuleItem, RuleSubsection } from './types';
import './RulesTablet.css';



const GetParentResourceName = () => 'null-core';

// ============================================================================
// RULES DATA
// ============================================================================

const RULES_DATA: RulesCategory[] = [
  {
    id: 'global',
    label: 'Règlement Global',
    icon: 'scroll',
    color: '#3498db',
    sections: [
      {
        id: 'general',
        title: 'I. Règles Générales',
        icon: 'book',
        color: '#3498db',
        rules: [
          { text: "La vente d'argent ou de biens in-game contre de l'argent réel est strictement interdite.", type: 'rule' },
          { text: "Aucun remboursement n'est effectué en cas de perte en jeu.", type: 'rule' },
          { text: "Sauf bugs de notre part, une preuve sera évidemment demandée !", type: 'note' },
          { text: "Il est interdit de léguer ses biens avant de quitter le serveur ou avant un wipe. Tout objet transféré sera supprimé, le donneur ainsi que le receveur seront sanctionnés lourdement.", type: 'rule' },
          { text: "Les véhicules ont un nombre de places prédéfini. Il est interdit de porter quelqu'un pour augmenter ce nombre.", type: 'rule' },
          { text: "Les termes faisant référence au staff ou au fait que vous enregistrez (papillons, gopro, Dieu, drône, là-haut, etc.) ne sont pas à utiliser et sont sanctionnables.", type: 'rule' },
          { text: "Après un wipe, il est impossible de créer un personnage avec un lien familial dans le but de venger la mort du précédent ou autre.", type: 'rule' },
        ]
      },
      {
        id: 'boutique',
        title: 'II. Règlement Boutique',
        icon: 'shopping',
        color: '#e67e22',
        rules: [
          { text: "Vous disposez de 14 jours de rétractation dans le cadre d'un achat en ligne. Pour toute rétractation, faites les démarches auprès de Tebex.", type: 'rule' },
          { text: "Acheter sur la boutique ne vous donne aucun avantage ou passe-droit concernant le serveur.", type: 'rule' },
          { text: "En cas de bannissement permanent ou blacklist, vos biens boutique peuvent être supprimés avec votre personnage si vous êtes débanni.", type: 'warning' },
          { text: "Les véhicules boutique doivent toujours être cohérents avec votre activité.", type: 'rule' },
          { text: "Il est interdit de fuir dans les montagnes avec une Audi RS6 ABT.", type: 'example' },
          { text: "Les armes permanentes ne peuvent pas être confisquées par les forces de l'ordre, mais leur présence sur une scène peut conduire à des sanctions (amendes, TIG, etc.).", type: 'rule' },
          { text: "Un joueur ne peut pas voler une arme permanente lors d'une scène illégale.", type: 'rule' },
          { text: "Les gains consommables (argent, etc.) ne sont pas permanents et ne peuvent pas être remboursés en cas de wipe.", type: 'rule' },
        ]
      },
      {
        id: 'graphique',
        title: 'III. Règlement Pack Graphique',
        icon: 'monitor',
        color: '#9b59b6',
        rules: [
          { text: "Il est strictement interdit de posséder un pack pouvant avantager votre gameplay (pack PVP).", type: 'rule' },
          { text: "Clearnight", type: 'forbidden' },
          { text: "No night", type: 'forbidden' },
          { text: "No bush", type: 'forbidden' },
          { text: "No props", type: 'forbidden' },
          { text: "No water", type: 'forbidden' },
          { text: "Hit effect", type: 'forbidden' },
          { text: "Kill effect", type: 'forbidden' },
          { text: "Tracer effect", type: 'forbidden' },
          { text: "Modification d'hitbox", type: 'forbidden' },
          { text: "Pack \"balles droites\"", type: 'forbidden' },
          { text: "Kick au premier coup, puis ban de 1 jour si récidive, ensuite 2 jours, etc.", type: 'sanction' },
        ]
      },
    ]
  },
  {
    id: 'roleplay',
    label: 'Règlement Roleplay',
    icon: 'theater',
    color: '#2ecc71',
    sections: [
      {
        id: 'rp-general',
        title: 'I. Règles RP Générales',
        icon: 'book',
        color: '#2ecc71',
        rules: [
          { text: "Le respect et la politesse sont primordiaux. Les insultes RP sont tolérées jusqu'à certaines limites (propos racistes, harcèlement, etc. sont interdits).", type: 'rule' },
          { text: "L'utilisation de radios extérieures (Discord, TeamSpeak, Mumble...) est à caractère HRP. Utilisez la radio en jeu pour vos scènes RP. Le staff peut sanctionner si des informations RP sont données via des radios HRP.", type: 'rule' },
          { text: "Toute activité illégale effectuée sur le site d'un événement organisé est interdite et passible d'un bannissement temporaire.", type: 'rule' },
          { text: "L'utilisation du dialecte HRP en jeu est formellement interdite. En cas de problème lors d'une scène, jouez-la correctement jusqu'au bout puis réglez le problème avec un membre du staff.", type: 'rule' },
          { text: "Pour une plainte visant un groupe ou un joueur, réunissez des preuves suffisantes (vidéo, screenshot, témoignage, etc.).", type: 'note' },
          { text: "Quitter une action RP avant qu'elle ne soit terminée (ALT+F4 ou tout autre moyen) est interdit. Il est également interdit de rester AFK dans des zones hautement convoitées.", type: 'rule' },
          { text: "L'utilisation d'un modificateur de voix ou d'un soundboard est strictement interdite. La modération peut exceptionnellement accorder une autorisation.", type: 'rule' },
          { text: "Il est interdit de prétendre connaître quelqu'un de masqué de par son accent, sa voix ou par des déductions basées sur le nombre de joueurs possédant telles armes/voitures/tenues.", type: 'rule' },
          { text: "Les vols de véhicules devant un commissariat ou un hôpital sont interdits.", type: 'rule' },
          { text: "Le menu PED vous permet d'avoir un ped pour votre RP. Pour cela, vous devez wipe ou faire une demande au staff via un ticket.", type: 'rule' },
          { text: "Il est interdit de donner des biens à des nouveaux joueurs en grande quantité.", type: 'rule' },
        ]
      },
      {
        id: 'streamers',
        title: 'II. Règlement Streamers',
        icon: 'video',
        color: '#e74c3c',
        rules: [
          { text: "Il est interdit de se rendre sur les points chauds en live.", type: 'rule' },
          { text: "Il est obligatoire d'installer un cache-map (image sur votre carte) afin d'éviter le streamhack.", type: 'rule' },
          { text: "Il est interdit d'utiliser sa communauté pour propager de la haine sur le serveur. L'incitation au troll est lourdement sanctionnée.", type: 'rule' },
          { text: "Vous serez tenu responsable des actions de votre communauté.", type: 'warning' },
        ]
      },
      {
        id: 'coma',
        title: 'III. Règlement Coma & Réanimation',
        icon: 'skull',
        color: '#e74c3c',
        rules: [
          { text: "Quand vous tombez dans le coma, il est strictement interdit de parler. À votre réveil, il est interdit de vous souvenir de choses précises.", type: 'rule' },
          { text: "Optez pour un détail flou : une couleur qui vous revient, la couleur d'un vêtement ou un tatouage sans le décrire précisément.", type: 'example' },
          { text: "Quand vous êtes transporté à l'hôpital après une scène avec la police, il est interdit de vous débarrasser de vos armes ou objets en les donnant à un autre joueur ou en les jetant.", type: 'rule' },
          { text: "Tous joueurs blessés ou inconscients sont déshabillés, fouillés et le contenu de leurs poches est confisqué.", type: 'note' },
          { text: "Il est interdit de parler à un joueur dans le coma (trash coma interdit).", type: 'rule' },
          { text: "Tuer quelqu'un et aller vers lui pour lui dire qu'il a été nul dans son gunfight, c'est interdit.", type: 'example' },
          { text: "Il est interdit de retourner sur une scène après avoir été réanimé, que ce soit par un EMS ou via un kit de réanimation.", type: 'rule' },
        ]
      },
    ]
  },
  {
    id: 'entreprises',
    label: 'Règlement Entreprises',
    icon: 'building',
    color: '#f39c12',
    sections: [
      {
        id: 'lspd',
        title: 'I. Règlement LSPD / BCSO',
        icon: 'shield',
        color: '#3498db',
        intro: "En tant que membre des forces de l'ordre et représentant de la loi, vous devez assurer un certain respect de votre fonction et des citoyens.",
        rules: [
          { text: "Lorsque vous rejoignez une scène de gunfight entre deux groupes (ou plus), vous devez attendre 1 minute avant de prendre les mesures nécessaires.", type: 'rule' },
          { text: "Si vous recevez des tirs, vous pouvez ouvrir le feu sans attendre la minute d'attente.", type: 'note' },
          { text: "Si les groupes commencent à fuir, la minute d'attente n'est plus nécessaire et la police peut prendre en chasse.", type: 'note' },
          { text: "Tout abus de provocation envers la LSPD/BCSO est sanctionnable.", type: 'rule' },
          { text: "Il est interdit de se faire passer pour la BAC (SCU) ou tout autre service de police. De lourdes sanctions peuvent être appliquées.", type: 'rule' },
          { text: "Un policier peut être corrompu uniquement avec l'accord des staffs (sous dossier).", type: 'rule' },
          { text: "Les PNJ sont considérés comme des êtres humains, toute action envers eux peut être soumise au jugement de la LSPD/BCSO.", type: 'rule' },
          { text: "Un policier ne peut pas faire son service en véhicule civilisé, ni se balader hors-service en véhicule de fonction.", type: 'rule' },
          { text: "Un agent ne doit jamais ouvrir le feu en premier (sauf sommation ou danger de mort).", type: 'rule' },
          { text: "L'utilisation de l'arme létale doit être la dernière issue ou par pure légitime défense.", type: 'rule' },
          { text: "Un policier peut effectuer un PIT au bout d'au moins 4 minutes de course-poursuite et plusieurs sommations. L'appel d'un hélicoptère est possible au bout de 10 minutes.", type: 'rule' },
          { text: "La revente ou le don d'armes de service est strictement interdit.", type: 'rule' },
          { text: "Il est interdit d'intervenir sur une scène illégale préparée à plus de 3 gangs. Les forces de l'ordre doivent attendre la fin de la scène.", type: 'rule' },
          { text: "La police peut échanger un otage contre $50,000 sur des scènes de bijouterie, Fleeca ou musée.", type: 'rule' },
          { text: "La police peut tenter un assaut stratégique uniquement si elle est sûre de ne blesser aucun otage. En cas d'échec, la somme prévue est doublée.", type: 'note' },
        ]
      },
      {
        id: 'ems',
        title: 'II. Règlement EMS',
        icon: 'ambulance',
        color: '#e74c3c',
        rules: [
          { text: "L'illégal est autorisé pour les ambulanciers, mais il est interdit d'utiliser ses droits d'ambulancier durant des scènes illégales (sous peine de lourdes sanctions).", type: 'rule' },
          { text: "Un EMS ne doit pas intervenir sur une scène de fusillade en cours. Mettez-vous à l'abri et attendez la fin.", type: 'rule' },
          { text: "Un EMS en service est dans l'obligation de venir en aide à son prochain et ne doit en aucun cas attenter à la vie d'une personne.", type: 'rule' },
          { text: "Un EMS doit jouer sa scène correctement à l'hôpital, pas simplement relever la personne et mettre une facture.", type: 'rule' },
          { text: "Une personne mise dans le coma par balle doit être transportée à l'hôpital le plus rapidement possible.", type: 'note' },
          { text: "Il est interdit d'utiliser l'unité-X pour échapper à une scène. Assurez-vous que la scène soit terminée avant.", type: 'rule' },
        ]
      },
      {
        id: 'entreprises-general',
        title: 'III. Règlement Entreprises Général',
        icon: 'building',
        color: '#f39c12',
        rules: [
          { text: "La gestion de votre entreprise doit être cohérente. Vous ne devez en aucun cas retirer des sommes astronomiques du compte de l'entreprise.", type: 'rule' },
          { text: "Quand vous quittez votre entreprise, vous pouvez uniquement prendre 20% de la somme totale du coffre.", type: 'rule' },
          { text: "Il est interdit d'effectuer des services gratuits à l'égard d'une société (custom gratuit au mécano, voiture gratuite au concessionnaire, etc.).", type: 'rule' },
          { text: "Un patron ne peut acquérir qu'une seule société.", type: 'rule' },
          { text: "Il est possible pour tout citoyen de faire la demande de création d'une entreprise en respectant les conditions suivantes :", type: 'rule' },
          { text: "Faire un dossier indiquant : le lieu du siège, les services proposés, l'histoire de l'entreprise, et être irréprochable dans votre RP.", type: 'sub' },
          { text: "Pour faire votre demande, rendez-vous sur le Discord dans la section \"Support\" > \"Ticket\" > \"Ticket Légal\".", type: 'note' },
          { text: "Il est interdit de prendre des objets d'un coffre d'entreprise pour votre utilisation personnelle.", type: 'rule' },
          { text: "Les commandes de masse aux entreprises ne sont autorisées qu'en tant qu'entreprise, par les Patrons/Co-Patrons.", type: 'rule' },
          { text: "Il est interdit de quitter une entreprise sans rendre les biens qui lui appartiennent.", type: 'rule' },
          { text: "La police/Gruppe 6 vous donne des armes pour votre service : quand vous quittez, vous devez les rendre.", type: 'example' },
          { text: "Cette règle concerne principalement les armes. Pour les consommables (nourriture, bandages), la règle ne s'applique pas.", type: 'note' },
        ]
      },
    ]
  },
  {
    id: 'illegal',
    label: 'Règlement Illégal',
    icon: 'skull',
    color: '#e74c3c',
    sections: [
      {
        id: 'braquage',
        title: 'I. Braquages & Prises d\'otage',
        icon: 'sword',
        color: '#e74c3c',
        subsections: [
          {
            id: 'epicerie',
            title: 'Épicerie',
            intro: "Le braquage d'épicerie est courant. Respectez le fairplay et la cohérence RP en vous mettant un minimum en difficulté.",
            rules: [
              { text: "Faire une prise d'otage ou braquer à plus de 4 personnes n'est pas cohérent avec les gains d'une épicerie.", type: 'rule' },
              { text: "Les armes utilisées doivent être proportionnées à l'action. L'utilisation d'armes lourdes est interdite — favorisez les pistolets.", type: 'rule' },
              { text: "Attendez l'arrivée de la police afin d'entrer en interaction avec elle. La course-poursuite n'est pas le seul moyen de fuir.", type: 'rule' },
              { text: "Les otages ne peuvent pas être des joueurs consentants ou des membres du groupe (faux otages).", type: 'rule' },
            ]
          },
          {
            id: 'general-braquage',
            title: 'Règles générales',
            rules: [
              { text: "La prise d'information et le contre-braquage sont interdits sur les scènes de bijouterie, banque et épicerie (côté braqueur uniquement).", type: 'rule' },
              { text: "Les rançons pour des prises d'otages entre groupes doivent être payées uniquement en argent sale ou drogue.", type: 'rule' },
              { text: "Argent sale : max $30,000 par otage.", type: 'note' },
              { text: "Drogue : max 40 unités par otage.", type: 'note' },
              { text: "Pas de loot sur l'otage.", type: 'forbidden' },
              { text: "Le braquage minute est interdit. Attendez l'arrivée des forces de l'ordre avant de partir.", type: 'rule' },
              { text: "Supérette : attendre 7 minutes la LSPD/BCSO.", type: 'note' },
              { text: "Fleeca / Pacifique / Bijouterie : attendre 10 minutes la LSPD/BCSO.", type: 'note' },
            ]
          },
        ],
        rules: []
      },
      {
        id: 'braquage-civil',
        title: 'II. Braquage de Civils',
        icon: 'sword',
        color: '#e67e22',
        rules: [
          { text: "Il est interdit de braquer une personne sans raison valable. Braquer uniquement pour l'argent n'est pas accepté.", type: 'rule' },
          { text: "Raisons valables : port d'un gilet pare-balle, exhibition d'une arme, joueur masqué, point chaud, prise d'otage pour supérette/bijouterie (sans loot).", type: 'allowed' },
          { text: "Il est interdit de voler plus de 50% de ce que possède le joueur braqué s'il est coopératif (sauf armes).", type: 'rule' },
          { text: "Il est interdit de dépouiller un civil utilisé uniquement comme otage (valable aussi pour les véhicules).", type: 'rule' },
          { text: "Il est interdit de torturer, amputer, lacérer, brûler ou violer quelqu'un sans l'accord HRP d'un modérateur et du joueur.", type: 'rule' },
          { text: "Il est interdit de braquer les patrons/employés durant la remise de paie.", type: 'rule' },
          { text: "Il est interdit de braquer un EMS pour soigner une personne, sauf en cas de scène importante ou d'événement.", type: 'rule' },
          { text: "Vous ne pouvez pas kidnapper quelqu'un et le ramener sur votre territoire officiel. Choisissez un lieu neutre (ruelle, hangar abandonné, etc.).", type: 'rule' },
        ]
      },
      {
        id: 'independants',
        title: 'III. Indépendants',
        icon: 'users',
        color: '#9b59b6',
        rules: [
          { text: "La limite de membres dans un groupe d'indépendants est de 6 joueurs.", type: 'rule' },
          { text: "Bannissement de 3 jours minimum pour les leads du groupe en cas d'infraction (récidive = plus de jours).", type: 'sanction' },
        ]
      },
      {
        id: 'transactions',
        title: 'IV. Transactions Illégales',
        icon: 'banknote',
        color: '#27ae60',
        rules: [
          { text: "Lorsque vous blanchissez de l'argent sale, vous devez le faire de façon cohérente.", type: 'rule' },
          { text: "Lors d'une transaction, vous pouvez blanchir jusqu'à 50% de la somme donnée en sale.", type: 'warning' },
          { text: "Un client veut blanchir $100,000 d'argent sale → il recevra $50,000 d'argent propre.", type: 'example' },
          { text: "Il est interdit d'acheter des objets illégaux ou points illégaux avec de l'argent propre.", type: 'rule' },
          { text: "Acheter une arme illégale avec de l'argent propre est interdit.", type: 'example' },
          { text: "L'acheteur et le vendeur s'exposent à un bannissement de 5 jours et un wipe de leur inventaire.", type: 'sanction' },
          { text: "L'arnaque dans l'illégal est autorisée, mais les notions de fairplay restent valables.", type: 'rule' },
          { text: "Il est interdit de vendre un point de drogue en dessous de $300,000 d'argent sale.", type: 'rule' },
          { text: "Un client veut le circuit de cocaïne → le vendeur doit le vendre pour minimum $1,000,000 d'argent sale.", type: 'example' },
        ]
      },
      {
        id: 'labo-territoire',
        title: 'V. Laboratoires & Territoires',
        icon: 'flask',
        color: '#1abc9c',
        rules: [
          { text: "Il est interdit de posséder plus d'un laboratoire par groupe officiel.", type: 'rule' },
          { text: "Pour un groupe officiel, il est interdit de contrôler plus de deux zones de territoires différentes.", type: 'rule' },
          { text: "Posséder la zone de la plage et Mirrors Parks en même temps (2 zones).", type: 'allowed' },
          { text: "Posséder la zone de la plage, Mirrors Parks et Vinewood en même temps (3 zones).", type: 'forbidden' },
        ]
      },
    ]
  },
];

// ============================================================================
// COMPONENT
// ============================================================================

interface RulesTabletProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
  serverConfig?: {
    serverName: string;
    serverColor: string;
    serverIcon: string;
  };
}

const iconMap: Record<string, React.ReactNode> = {
  scroll: <Scroll size={18} />,
  book: <BookOpen size={18} />,
  shopping: <ShoppingBag size={18} />,
  monitor: <Monitor size={18} />,
  theater: <Theater size={18} />,
  video: <Video size={18} />,
  skull: <Skull size={18} />,
  building: <Building2 size={18} />,
  shield: <Shield size={18} />,
  siren: <Siren size={18} />,
  ambulance: <HeartPulse size={18} />,
  sword: <Sword size={18} />,
  users: <Users size={18} />,
  banknote: <Banknote size={18} />,
  flask: <FlaskConical size={18} />,
  handshake: <HeartHandshake size={18} />,
  map: <MapPin size={18} />,
};

const allSections = RULES_DATA.flatMap(cat =>
  cat.sections.map(sec => ({ ...sec, categoryId: cat.id, categoryLabel: cat.label, categoryColor: cat.color }))
);

const RulesTablet: React.FC<RulesTabletProps> = ({ visible, onClose, primaryColor, serverConfig }) => {
  const accentColor = primaryColor || '#64abed';
  const brandLogo = serverConfig?.serverIcon || null;
  const rulesAccentVars = useMemo(() => generateAccentVars('--rules-accent', accentColor), [accentColor]);
  const rulesBrandVars = useMemo(() => ({
    '--rules-brand-bg': '#1a1a1a',
    '--rules-brand-accent': accentColor,
  } as React.CSSProperties), [accentColor]);

  const [activeSectionId, setActiveSectionId] = useState<string>(allSections[0]?.id || '');
  const [searchQuery, setSearchQuery] = useState('');
  const [hiding, setHiding] = useState(false);
  const contentRef = useRef<HTMLDivElement>(null);
  const searchInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!visible) {
      setHiding(false);
      setSearchQuery('');
      setActiveSectionId(allSections[0]?.id || '');
    }
  }, [visible]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!visible) return;
      if (e.key === 'Escape') {
        handleClose();
      }
      if ((e.ctrlKey || e.metaKey) && e.key === 'f') {
        e.preventDefault();
        searchInputRef.current?.focus();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [visible]);

  const handleClose = useCallback(async () => {
    if (hiding) return;
    setHiding(true);
    // Call NUI callback immediately to release focus
    try {
      await fetch(`https://${GetParentResourceName()}/reglement:close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });
    } catch (e) {
      // Ignore errors
    }
    setTimeout(() => {
      setHiding(false);
      setSearchQuery('');
      setActiveSectionId(allSections[0]?.id || '');
      onClose();
    }, 300);
  }, [hiding, onClose]);

  const currentSection = useMemo(() => {
    return allSections.find(s => s.id === activeSectionId) || allSections[0];
  }, [activeSectionId]);

  const searchResults = useMemo(() => {
    if (!searchQuery.trim()) return null;
    const query = searchQuery.toLowerCase().trim();
    const results: { category: RulesCategory; section: RuleSection; subsection?: RuleSubsection; rule: RuleItem }[] = [];

    for (const cat of RULES_DATA) {
      for (const sec of cat.sections) {
        for (const rule of sec.rules) {
          if (rule.text.toLowerCase().includes(query)) {
            results.push({ category: cat, section: sec, rule });
          }
        }
        if (sec.subsections) {
          for (const sub of sec.subsections) {
            for (const rule of sub.rules) {
              if (rule.text.toLowerCase().includes(query)) {
                results.push({ category: cat, section: sec, subsection: sub, rule });
              }
            }
          }
        }
      }
    }
    return results;
  }, [searchQuery]);

  const navigateToSection = (sectionId: string) => {
    setActiveSectionId(sectionId);
    setSearchQuery('');
    if (contentRef.current) contentRef.current.scrollTop = 0;
  };

  const highlightText = (text: string, query: string) => {
    if (!query.trim()) return text;
    const regex = new RegExp(`(${query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`, 'gi');
    const parts = text.split(regex);
    return parts.map((part, i) =>
      regex.test(part) ? <mark key={i} className="rules-highlight">{part}</mark> : part
    );
  };

  const renderRuleIcon = (type: RuleItem['type']) => {
    switch (type) {
      case 'forbidden': return <XCircle size={14} className="rule-icon rule-icon-forbidden" />;
      case 'allowed': return <CheckCircle2 size={14} className="rule-icon rule-icon-allowed" />;
      case 'warning': return <AlertTriangle size={14} className="rule-icon rule-icon-warning" />;
      case 'sanction': return <AlertTriangle size={14} className="rule-icon rule-icon-sanction" />;
      case 'example': return <FileText size={14} className="rule-icon rule-icon-example" />;
      case 'note': return <Info size={14} className="rule-icon rule-icon-note" />;
      case 'sub': return <ChevronRight size={14} className="rule-icon rule-icon-sub" />;
      default: return <div className="rule-bullet" />;
    }
  };

  const renderRule = (rule: RuleItem, index: number, query?: string) => {
    return (
      <div key={index} className={`rule-item rule-type-${rule.type}`}>
        {renderRuleIcon(rule.type)}
        <span className="rule-text">
          {query ? highlightText(rule.text, query) : rule.text}
        </span>
      </div>
    );
  };

  const renderCurrentSection = () => {
    if (!currentSection) return null;
    return (
      <div className="rules-page">
        {currentSection.intro && (
          <p className="rules-section-intro">{currentSection.intro}</p>
        )}

        {currentSection.rules.length > 0 && (
          <div className="rules-list">
            {currentSection.rules.map((rule, i) => renderRule(rule, i))}
          </div>
        )}

        {currentSection.subsections && currentSection.subsections.map(sub => (
          <div key={sub.id} className="rules-subsection">
            <h4 className="rules-subsection-title">{sub.title}</h4>
            {sub.intro && <p className="rules-subsection-intro">{sub.intro}</p>}
            <div className="rules-list">
              {sub.rules.map((rule, i) => renderRule(rule, i))}
            </div>
          </div>
        ))}
      </div>
    );
  };

  const renderSearchResults = () => {
    if (!searchResults) return null;

    if (searchResults.length === 0) {
      return (
        <div className="rules-no-results">
          <Search size={48} strokeWidth={1} />
          <p>Aucun résultat pour "<strong>{searchQuery}</strong>"</p>
          <span>Essayez avec d'autres termes</span>
        </div>
      );
    }

    const grouped = searchResults.reduce((acc, r) => {
      const key = `${r.category.id}__${r.section.id}`;
      if (!acc[key]) {
        acc[key] = { category: r.category, section: r.section, rules: [] };
      }
      acc[key].rules.push(r.rule);
      return acc;
    }, {} as Record<string, { category: RulesCategory; section: RuleSection; rules: RuleItem[] }>);

    return (
      <div className="rules-search-results">
        <div className="rules-search-count">
          {searchResults.length} résultat{searchResults.length > 1 ? 's' : ''} trouvé{searchResults.length > 1 ? 's' : ''}
        </div>
        {Object.values(grouped).map((group, i) => (
          <div key={i} className="rules-search-group">
            <div
              className="rules-search-group-header"
              onClick={() => navigateToSection(group.section.id)}
            >
              <div className="rules-search-group-badge" style={{ background: group.section.color }}>
                {iconMap[group.section.icon] || <BookOpen size={14} />}
              </div>
              <div className="rules-search-group-info">
                <span className="rules-search-group-cat">{group.category.label}</span>
                <span className="rules-search-group-title">{group.section.title}</span>
              </div>
              <ChevronRight size={16} />
            </div>
            <div className="rules-search-group-rules">
              {group.rules.map((rule, j) => renderRule(rule, j, searchQuery))}
            </div>
          </div>
        ))}
      </div>
    );
  };

  if (!visible) return null;

  return (
    <div className={`rules-overlay ${hiding ? 'rules-hiding' : ''}`}>
      <div className="rules-container" style={{ ...rulesAccentVars, ...rulesBrandVars } as React.CSSProperties}>
        {/* Sidebar */}
        <div className="rules-sidebar">
          {/* Brand Hero Header */}
          <div className="rules-brand-hero">
            <div className="rules-brand-hero-inner">
              {brandLogo && (
                <img src={brandLogo} alt="" className="rules-brand-logo" />
              )}
              <div className="rules-brand-hero-text">
                <h1>{serverConfig?.serverName || 'Null'}</h1>
                <p>Règlement</p>
              </div>
            </div>
          </div>

          <nav className="rules-sidebar-nav">
            {RULES_DATA.map(cat => (
              <div key={cat.id} className="rules-nav-category">
                {cat.sections.map(sec => (
                  <button
                    key={sec.id}
                    className={`rules-sidebar-item ${activeSectionId === sec.id && !searchQuery ? 'active' : ''}`}
                    onClick={() => navigateToSection(sec.id)}
                  >
                    {activeSectionId === sec.id && !searchQuery && <div className="rules-sidebar-indicator" style={{ background: accentColor }} />}
                    {iconMap[sec.icon] || <BookOpen size={16} />}
                    <span>{sec.title.replace(/^[IVX]+\.\s*/, '')}</span>
                    <ChevronRight size={14} className="rules-sidebar-arrow" />
                  </button>
                ))}
              </div>
            ))}
          </nav>

          <div className="rules-sidebar-footer">
            <button className="rules-close-sidebar-btn" onClick={handleClose}>
              <X size={16} />
              <span>Fermer</span>
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="rules-content" ref={contentRef}>
          {/* Ambient gradient tint */}
          {/* <div
            className="rules-brand-ambient"
            style={{
              background: `radial-gradient(circle at 0% 0%, ${accentColor}44 0%, transparent 55%)`,
            }}
            aria-hidden
          /> */}
          <div className="rules-content-header">
            <div className="rules-content-header-info">
              {searchQuery ? (
                <h2>Recherche</h2>
              ) : currentSection ? (
                <>
                  <span className="rules-content-header-cat">{currentSection.categoryLabel}</span>
                  <h2>{currentSection.title}</h2>
                </>
              ) : null}
            </div>
            <div className="rules-search">
              <Search size={16} />
              <input
                ref={searchInputRef}
                type="text"
                placeholder="Rechercher... (Ctrl+F)"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
              {searchQuery && (
                <button className="rules-search-clear" onClick={() => setSearchQuery('')}>
                  <X size={14} />
                </button>
              )}
            </div>
          </div>

          <div className="rules-content-body">
            {searchQuery ? (
              renderSearchResults()
            ) : (
              renderCurrentSection()
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default RulesTablet;

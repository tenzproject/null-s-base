import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import {
  Sparkles, BookOpen, Shield, Scale, Skull, Gamepad2, Car,
  ChevronRight, X, Rocket, Users, Briefcase,
  Swords, Crown, Target, Map, Star,
  Monitor, MessageSquare, Keyboard, ArrowRight,
  CheckCircle2, Zap, Heart, AlertTriangle, Eye,
  Shirt, Navigation, Flag, Trophy, HeartHandshake,
  Wrench, Smartphone, Bike
} from 'lucide-react';
import './Tutorial.css';

const GetParentResourceName = () => 'null-core';

// ============================================================================
// TYPES
// ============================================================================

interface TutorialProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
  serverConfig: {
    serverName: string;
    serverIcon: string;
  };
}

interface StepContent {
  title: string;
  subtitle?: string;
  icon: React.ReactNode;
  content: React.ReactNode;
  actions?: { label: string; action: string; icon?: React.ReactNode; variant?: 'primary' | 'secondary' | 'danger'; data?: Record<string, any> }[];
  progress?: number;
}

type TutorialPath = 'legal' | 'illegal' | null;

const nuiCallback = async (event: string, data: Record<string, any> = {}) => {
  try {
    await fetch(`https://${GetParentResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
  } catch (e) {
    // silent
  }
};

// ============================================================================
// COMPONENT
// ============================================================================

const Tutorial: React.FC<TutorialProps> = ({ visible, onClose, primaryColor, serverConfig }) => {
  const accentColor = primaryColor || '#BEEE11';
  const tutorialAccentVars = useMemo(() => generateAccentVars('--tutorial-accent', accentColor), [accentColor]);
  const [currentStep, setCurrentStep] = useState<string>('welcome');
  const [path, setPath] = useState<TutorialPath>(null);
  const [hiding, setHiding] = useState(false);
  const [animating, setAnimating] = useState(false);
  const [discordLink, setDiscordLink] = useState('');
  const [jobs, setJobs] = useState<{ name: string; description: string }[]>([]);

  useEffect(() => {
    if (!visible) {
      setCurrentStep('welcome');
      setPath(null);
      setHiding(false);
    }
  }, [visible]);

  const handleMessage = useCallback((event: MessageEvent) => {
    const { action, data } = event.data;
    if (!action) return;

    switch (action) {
      case 'tutorial:updateStep':
        if (data?.step) {
          setAnimating(true);
          setTimeout(() => {
            setCurrentStep(data.step);
            if (data.path) setPath(data.path);
            setAnimating(false);
          }, 200);
        }
        break;
    }
  }, []);

  useEffect(() => {
    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [handleMessage]);

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const { action, data } = event.data;
      if (action === 'tutorial:open' && data?.config) {
        setDiscordLink(data.config.discordLink || '');
        if (data.config.jobs) setJobs(data.config.jobs);
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  const handleAction = useCallback((actionType: string, data?: Record<string, any>) => {
    switch (actionType) {
      case 'skip':
        nuiCallback('tutorial:skip');
        break;
      case 'startTutorial':
        nuiCallback('tutorial:startTutorial');
        break;
      case 'nextStep':
        nuiCallback('tutorial:nextStep', { nextStep: data?.nextStep, extra: data?.extra });
        break;
      case 'choosePath':
        nuiCallback('tutorial:choosePath', { path: data?.path });
        break;
      case 'continueToDriveschool':
        nuiCallback('tutorial:continueToDriveschool');
        break;
      case 'continueAfterLicense':
        nuiCallback('tutorial:continueAfterLicense');
        break;
      case 'continueAfterVehicle':
        nuiCallback('tutorial:continueAfterVehicle');
        break;
      case 'continueToJobCenter':
        nuiCallback('tutorial:continueToJobCenter');
        break;
      case 'enterClothingShop':
        nuiCallback('tutorial:enterClothingShop');
        break;
      case 'releaseControls':
        nuiCallback('tutorial:releaseControls', { target: data?.target });
        break;
      case 'complete':
        nuiCallback('tutorial:complete');
        break;
    }
  }, []);

  // ============================================================================
  // STEP DEFINITIONS
  // ============================================================================

  const getStepContent = useCallback((): StepContent | null => {
    switch (currentStep) {
      // ==================== WELCOME ====================
      case 'welcome':
        return {
          title: 'Bienvenue !',
          subtitle: 'Votre aventure commence ici',
          icon: <Sparkles size={28} />,
          progress: 0,
          content: (
            <div className="tutorial-welcome">
              <div className="tutorial-welcome-hero">
                <div className="tutorial-welcome-glow" />
                {serverConfig.serverIcon ? (
                  <img src={serverConfig.serverIcon} alt="" className="tutorial-welcome-logo" />
                ) : (
                  <div className="tutorial-welcome-logo-fallback" style={{ background: accentColor }}>
                    <Sparkles size={32} />
                  </div>
                )}
                <h1>Bienvenue sur {serverConfig.serverName || 'le serveur'} !</h1>
                <p>Nous sommes ravis de vous accueillir parmi nous. Ce tutoriel interactif va vous accompagner pas à pas pour découvrir le serveur, comprendre les règles et démarrer votre aventure.</p>
              </div>

              <div className="tutorial-welcome-divider" />

              <div className="tutorial-welcome-features">
                <div className="tutorial-feature-card">
                  <BookOpen size={20} />
                  <span>Apprendre les bases du RP</span>
                </div>
                <div className="tutorial-feature-card">
                  <Shield size={20} />
                  <span>Comprendre le règlement</span>
                </div>
                <div className="tutorial-feature-card">
                  <Car size={20} />
                  <span>Obtenir votre permis et véhicule</span>
                </div>
                <div className="tutorial-feature-card">
                  <Briefcase size={20} />
                  <span>Découvrir les métiers</span>
                </div>
              </div>

              <p className="tutorial-welcome-note">
                <AlertTriangle size={14} /> Vous pouvez passer le tutoriel à tout moment, mais nous vous recommandons de le suivre.
              </p>
            </div>
          ),
          actions: [
            { label: 'Commencer', action: 'startTutorial', variant: 'primary' },
          ],
        };

      // ==================== CATEGORIES (all visible) ====================
      case 'categories':
        return {
          title: 'Programme du tutoriel',
          subtitle: 'Voici ce qui vous attend',
          icon: <BookOpen size={28} />,
          progress: 5,
          content: (
            <div className="tutorial-content-section">
              <div className="tutorial-info-block highlight">
                <h3><BookOpen size={18} /> Aperçu complet du tutoriel</h3>
                <p>Voici toutes les étapes que vous allez parcourir. Chaque étape vous guidera progressivement dans votre découverte du serveur.</p>
              </div>
              <div className="tutorial-steps-preview">
                <div className="tutorial-step-preview-item">
                  <div className="tutorial-step-number">1</div>
                  <div>
                    <strong>Les bases du RolePlay</strong>
                    <p>Apprenez les fondamentaux du RP et les règles essentielles</p>
                  </div>
                </div>
                <div className="tutorial-step-preview-item">
                  <div className="tutorial-step-number">2</div>
                  <div>
                    <strong>Le règlement</strong>
                    <p>Consultez les règles importantes du serveur</p>
                  </div>
                </div>
                <div className="tutorial-step-preview-item">
                  <div className="tutorial-step-number">3</div>
                  <div>
                    <strong>Les fonctionnalités</strong>
                    <p>Découvrez les raccourcis et outils à votre disposition</p>
                  </div>
                </div>
                <div className="tutorial-step-preview-item">
                  <div className="tutorial-step-number">4</div>
                  <div>
                    <strong>Choisir votre voie</strong>
                    <p>Légale ou illégale — à vous de décider</p>
                  </div>
                </div>
                <div className="tutorial-step-preview-item">
                  <div className="tutorial-step-number">5</div>
                  <div>
                    <strong>Permis de conduire</strong>
                    <p>Passez votre permis à l'auto-école</p>
                  </div>
                </div>
                <div className="tutorial-step-preview-item">
                  <div className="tutorial-step-number">6</div>
                  <div>
                    <strong>Véhicule gratuit</strong>
                    <p>Récupérez votre premier véhicule</p>
                  </div>
                </div>
                <div className="tutorial-step-preview-item">
                  <div className="tutorial-step-number">7</div>
                  <div>
                    <strong>Magasin de vêtements</strong>
                    <p>Personnalisez votre tenue</p>
                  </div>
                </div>
                <div className="tutorial-step-preview-item">
                  <div className="tutorial-step-number">8</div>
                  <div>
                    <strong>Pôle emploi</strong>
                    <p>Choisissez votre premier métier</p>
                  </div>
                </div>
              </div>
            </div>
          ),
          actions: [
            { label: 'C\'est parti !', action: 'nextStep', icon: <ChevronRight size={16} />, variant: 'primary', data: { nextStep: 'basics_rp' } },
          ],
        };

      // ==================== BASICS RP ====================
      case 'basics_rp':
        return {
          title: 'Les bases du RolePlay',
          subtitle: 'Ce que vous devez savoir',
          icon: <BookOpen size={28} />,
          progress: 10,
          content: (
            <div className="tutorial-content-section">
              <div className="tutorial-info-block">
                <h3><Users size={18} /> Qu'est-ce que le RolePlay ?</h3>
                <p>Le RolePlay (RP) consiste à <strong>incarner un personnage fictif</strong> dans un monde virtuel. Vous jouez un rôle, comme un acteur, avec une histoire, des motivations et une personnalité propres.</p>
              </div>
              <div className="tutorial-info-block">
                <h3><MessageSquare size={18} /> Communication</h3>
                <p>Utilisez le <strong>micro en jeu</strong> pour parler en tant que votre personnage. Tout ce que vous dites doit être cohérent avec votre rôle. Évitez de parler de choses hors-RP (HRP).</p>
              </div>
              <div className="tutorial-info-block">
                <h3><Heart size={18} /> Respect des autres</h3>
                <p>Chaque joueur incarne un personnage. Respectez les scénarios des autres, ne cassez pas l'immersion, et collaborez pour créer des histoires mémorables.</p>
              </div>
              <div className="tutorial-rules-summary">
                <h3><AlertTriangle size={18} /> Règles essentielles</h3>
                <ul>
                  <li><strong>Fear RP</strong> — Votre personnage doit avoir peur pour sa vie dans les situations dangereuses</li>
                  <li><strong>No Random DM</strong> — Ne tuez pas sans raison RP valable</li>
                  <li><strong>Metagaming</strong> — N'utilisez pas d'informations obtenues hors-RP</li>
                  <li><strong>Powergaming</strong> — Ne forcez pas des actions irréalistes</li>
                </ul>
              </div>
            </div>
          ),
          actions: [
            { label: 'Continuer', action: 'nextStep', icon: <ChevronRight size={16} />, variant: 'primary', data: { nextStep: 'rules_overview' } },
          ],
        };

      // ==================== RULES OVERVIEW ====================
      case 'rules_overview':
        return {
          title: 'Le Règlement',
          subtitle: 'Les règles à respecter',
          icon: <Shield size={28} />,
          progress: 20,
          content: (
            <div className="tutorial-content-section">
              <div className="tutorial-info-block highlight">
                <h3><Shield size={18} /> Règlement du serveur</h3>
                <p>Le serveur possède un règlement complet que vous pouvez consulter à tout moment avec la commande <code>/reglement</code>. Voici les points les plus importants :</p>
              </div>
              <div className="tutorial-rules-grid">
                <div className="tutorial-rule-card">
                  <div className="tutorial-rule-header">
                    <Skull size={18} />
                    <h4>Respect de la vie</h4>
                  </div>
                  <p>Votre personnage tient à sa vie. Agissez en conséquence face aux menaces.</p>
                </div>
                <div className="tutorial-rule-card">
                  <div className="tutorial-rule-header">
                    <Eye size={18} />
                    <h4>Pas de Metagaming</h4>
                  </div>
                  <p>N'utilisez jamais d'informations obtenues en dehors du jeu (stream, Discord, etc.).</p>
                </div>
                <div className="tutorial-rule-card">
                  <div className="tutorial-rule-header">
                    <HeartHandshake size={18} />
                    <h4>Fair-play</h4>
                  </div>
                  <p>Jouez de manière réaliste et respectez les scénarios des autres joueurs.</p>
                </div>
                <div className="tutorial-rule-card">
                  <div className="tutorial-rule-header">
                    <MessageSquare size={18} />
                    <h4>Communication</h4>
                  </div>
                  <p>Restez toujours en personnage. Utilisez /report pour les problèmes HRP.</p>
                </div>
                <div className="tutorial-rule-card">
                  <div className="tutorial-rule-header">
                    <AlertTriangle size={18} />
                    <h4>Interdit de HRP</h4>
                  </div>
                  <p>Ne sortez jamais de votre personnage. Le chat vocal et textuel est exclusivement réservé au jeu.</p>
                </div>
                <div className="tutorial-rule-card">
                  <div className="tutorial-rule-header">
                    <Car size={18} />
                    <h4>Conduite réaliste</h4>
                  </div>
                  <p>Adaptez votre conduite à l'environnement. Le 'Powergaming' (sauts irréalistes) est sanctionné.</p>
                </div>
                <div className="tutorial-rule-card">
                  <div className="tutorial-rule-header">
                    <Shield size={18} />
                    <h4>Comportement avec les services</h4>
                  </div>
                  <p>Le meurtre de policiers ou de médecins sans scène majeure est interdit.</p>
                </div>
                <div className="tutorial-rule-card">
                  <div className="tutorial-rule-header">
                    <Flag size={18} />
                    <h4>Zones de sécurité</h4>
                  </div>
                  <p>Aucun acte criminel n'est toléré dans les zones comme l'hôpital ou le commissariat.</p>
                </div>
              </div>
            </div>
          ),
          actions: [
            { label: 'Continuer', action: 'nextStep', icon: <ChevronRight size={16} />, variant: 'primary', data: { nextStep: 'features_overview' } },
          ],
        };

      // ==================== FEATURES OVERVIEW ====================
      case 'features_overview':
        return {
          title: 'Fonctionnalités',
          subtitle: 'Les outils à votre disposition',
          icon: <Gamepad2 size={28} />,
          progress: 30,
          content: (
            <div className="tutorial-content-section">
              <div className="tutorial-info-block">
                <h3><Keyboard size={18} /> Raccourcis essentiels</h3>
              </div>
              <div className="tutorial-keybinds-grid">
                <div className="tutorial-keybind">
                  <kbd>F5</kbd>
                  <div>
                    <strong>Menu Principal</strong>
                    <span>Gestion véhicule, animations, options</span>
                  </div>
                </div>
                <div className="tutorial-keybind">
                  <kbd>TAB</kbd>
                  <div>
                    <strong>Inventaire</strong>
                    <span>Gérer vos objets et équipements</span>
                  </div>
                </div>
                <div className="tutorial-keybind">
                  <kbd>F2</kbd>
                  <div>
                    <strong>Boutique</strong>
                    <span>Acheter des items avec des coins</span>
                  </div>
                </div>
                <div className="tutorial-keybind">
                  <kbd>T</kbd>
                  <div>
                    <strong>Chat</strong>
                    <span>Commandes et communication textuelle</span>
                  </div>
                </div>
                <div className="tutorial-keybind">
                  <kbd>F6</kbd>
                  <div>
                    <strong>Menu Job</strong>
                    <span>Actions liées à votre métier</span>
                  </div>
                </div>
                <div className="tutorial-keybind">
                  <kbd>ALT</kbd>
                  <div>
                    <strong>Interactions</strong>
                    <span>Interagir avec les joueurs et objets proches</span>
                  </div>
                </div>
                <div className="tutorial-keybind">
                  <kbd>F7</kbd>
                  <div>
                    <strong>Menu Illégal</strong>
                    <span>Actions liées à l'illégalité</span>
                  </div>
                </div>
                <div className="tutorial-keybind">
                  <kbd>?</kbd>
                  <div>
                    <strong>Personnalisation du HUD</strong>
                    <span>Personnalisez votre interface</span>
                  </div>
                </div>
              </div>
              <div className="tutorial-info-block">
                <h3><Monitor size={18} /> Personnalisation du HUD</h3>
                <p>Vous pouvez personnaliser entièrement votre interface via <strong>/hudedit</strong> ou <strong>F5 → Éditeur HUD</strong>. Déplacez, redimensionnez et changez les couleurs de chaque élément.</p>
              </div>
            </div>
          ),
          actions: [
            { label: 'Continuer', action: 'nextStep', icon: <ChevronRight size={16} />, variant: 'primary', data: { nextStep: 'choose_path' } },
          ],
        };

      // ==================== CHOOSE PATH ====================
      case 'choose_path':
        return {
          title: 'Votre Voie',
          subtitle: 'Quel chemin souhaitez-vous emprunter ?',
          icon: <Swords size={28} />,
          progress: 35,
          content: (
            <div className="tutorial-choice-section">
              <p className="tutorial-choice-intro">
                Ce choix influence la suite du tutoriel pour vous montrer les fonctionnalités adaptées.
                <strong> Vous pourrez toujours changer de voie en jeu !</strong>
              </p>
              <div className="tutorial-path-cards">
                <button
                  className="tutorial-path-card legal"
                  onClick={() => handleAction('choosePath', { path: 'legal' })}
                >
                  <div className="tutorial-path-card-icon">
                    <Scale size={36} />
                  </div>
                  <h3>Voie Légale</h3>
                  <p>Devenez un citoyen modèle. Exercez un métier, montez votre entreprise, et contribuez à la société.</p>
                  <div className="tutorial-path-tags">
                    <span><Briefcase size={12} /> Métiers</span>
                    <span><Users size={12} /> Communauté</span>
                  </div>
                  <div className="tutorial-path-arrow"><ArrowRight size={20} /></div>
                </button>
                <button
                  className="tutorial-path-card illegal"
                  onClick={() => handleAction('choosePath', { path: 'illegal' })}
                >
                  <div className="tutorial-path-card-icon">
                    <Skull size={36} />
                  </div>
                  <h3>Voie Illégale</h3>
                  <p>Fondez votre organisation criminelle. Contrôlez des territoires, gérez vos membres et dominez la ville.</p>
                  <div className="tutorial-path-tags">
                    <span><Crown size={12} /> Organisation</span>
                    <span><Target size={12} /> Missions</span>
                    <span><Map size={12} /> Territoires</span>
                  </div>
                  <div className="tutorial-path-arrow"><ArrowRight size={20} /></div>
                </button>
              </div>
            </div>
          ),
        };

      // ==================== PATH CHOSEN (legal or illegal intro + continue) ====================
      case 'path_chosen':
        if (path === 'illegal') {
          return {
            title: 'La Voie Illégale',
            subtitle: 'Le monde du crime',
            icon: <Skull size={28} />,
            progress: 40,
            content: (
              <div className="tutorial-content-section">
                <div className="tutorial-info-block highlight" style={{ borderColor: '#e74c3c33' }}>
                  <h3><Crown size={18} /> La Tablette Illégale (F7)</h3>
                  <p>Votre outil principal sera la <strong>tablette illégale</strong>, accessible avec <kbd>F7</kbd>. Elle vous permet de gérer votre organisation criminelle.</p>
                </div>
                <div className="tutorial-illegal-features">
                  <div className="tutorial-illegal-feature">
                    <Target size={18} />
                    <div>
                      <strong>Missions</strong>
                      <p>Complétez des missions quotidiennes et hebdomadaires pour gagner de l'XP et monter en niveau.</p>
                    </div>
                  </div>
                  <div className="tutorial-illegal-feature">
                    <Map size={18} />
                    <div>
                      <strong>Territoires</strong>
                      <p>Contrôlez des zones de la ville pour étendre votre influence et débloquer des avantages.</p>
                    </div>
                  </div>
                  <div className="tutorial-illegal-feature">
                    <Users size={18} />
                    <div>
                      <strong>Membres & Rangs</strong>
                      <p>Recrutez des membres, créez des rangs avec des permissions personnalisées.</p>
                    </div>
                  </div>
                  <div className="tutorial-illegal-feature">
                    <Zap size={18} />
                    <div>
                      <strong>Progression</strong>
                      <p>Votre gang évolue : Petite frappe → Gang de Rue → Réseau Mafieux → Empire Criminel.</p>
                    </div>
                  </div>
                  <div className="tutorial-illegal-feature">
                    <Smartphone size={18} />
                    <div>
                      <strong>CrimeNet</strong>
                      <p>Accédez à l'application CrimeNet depuis votre téléphone pour consulter le marché noir et passer des contrats anonymes.</p>
                    </div>
                  </div>
                </div>
                <div className="tutorial-info-block">
                  <h3><Bike size={18} /> Prochaine étape</h3>
                  <p>Avant toute chose, vous devez passer votre <strong>permis de conduire</strong>. Un <strong>BMX</strong> va être ajouté à votre inventaire pour vous rendre à l'auto-école. Utilisez-le depuis votre inventaire (<kbd>TAB</kbd>) pour le faire apparaître.</p>
                </div>
                <p className="tutorial-tip"><Skull size={14} /> Vous pourrez créer votre organisation via la tablette F7 une fois le tutoriel terminé.</p>
              </div>
            ),
            actions: [
              { label: 'Recevoir le BMX et aller à l\'auto-école', action: 'continueToDriveschool', icon: <Bike size={16} />, variant: 'primary' },
            ],
          };
        }
        return {
          title: 'La Voie Légale',
          subtitle: 'Découvrez les opportunités',
          icon: <Scale size={28} />,
          progress: 40,
          content: (
            <div className="tutorial-content-section">
              <div className="tutorial-info-block highlight">
                <h3><Briefcase size={18} /> Les métiers</h3>
                <p>Le serveur propose de nombreux métiers légaux : <strong>policier, médecin, mécanicien, taxi, livreur, fermier</strong> et bien d'autres. Chaque métier a ses propres mécaniques et interactions.</p>
              </div>
              <div className="tutorial-info-block">
                <h3><Star size={18} /> Créer votre propre métier</h3>
                <p>Vous avez une idée de métier unique ? Vous pouvez <strong>créer un ticket sur le Discord</strong> pour proposer un nouveau métier. L'équipe étudie chaque proposition !</p>
                {discordLink && (
                  <p className="tutorial-discord-link">
                    <MessageSquare size={14} /> Discord : <code>{discordLink}</code>
                  </p>
                )}
              </div>
              <div className="tutorial-info-block">
                <h3><Trophy size={18} /> Progression</h3>
                <p>Gagnez de l'argent, achetez des propriétés, des véhicules, et construisez votre réputation dans la ville. Les possibilités sont infinies !</p>
              </div>
              <div className="tutorial-info-block">
                <h3><Bike size={18} /> Prochaine étape</h3>
                <p>Avant toute chose, vous devez passer votre <strong>permis de conduire</strong>. Un <strong>BMX</strong> va être ajouté à votre inventaire pour vous rendre à l'auto-école. Utilisez-le depuis votre inventaire (<kbd>TAB</kbd>) pour le faire apparaître.</p>
              </div>
            </div>
          ),
          actions: [
            { label: 'Recevoir le BMX et aller à l\'auto-école', action: 'continueToDriveschool', icon: <Bike size={16} />, variant: 'primary' },
          ],
        };

      // ==================== GOTO DRIVESCHOOL (BMX) ====================
      case 'goto_driveschool':
        return {
          title: 'Direction l\'auto-école',
          subtitle: 'Suivez le GPS',
          icon: <Bike size={28} />,
          progress: 45,
          content: (
            <div className="tutorial-content-section">
              <div className="tutorial-info-block highlight">
                <h3><Bike size={18} /> Utilisez votre BMX</h3>
                <p>Un BMX a été ajouté à votre inventaire. Ouvrez votre inventaire avec <kbd>TAB</kbd> et utilisez l'item <strong>BMX</strong> pour le faire apparaître devant vous.</p>
              </div>
              <div className="tutorial-objective">
                <Navigation size={20} />
                <div>
                  <strong>Objectif : Rendez-vous à l'auto-école</strong>
                  <p>Suivez le marqueur sur votre GPS. Montez sur votre BMX et roulez jusqu'à l'auto-école.</p>
                </div>
              </div>
            </div>
          ),
          actions: [],
        };

      // ==================== WAITING DRIVESCHOOL ====================
      case 'waiting_driveschool':
        return {
          title: 'Auto-école',
          subtitle: 'Passez votre permis de conduire',
          icon: <Car size={28} />,
          progress: 50,
          content: (
            <div className="tutorial-content-section">
              <div className="tutorial-info-block highlight">
                <h3><Car size={18} /> Permis de conduire</h3>
                <p>Vous êtes arrivé à l'auto-école ! Fermez la tablette et approchez-vous du comptoir pour passer votre permis de conduire.</p>
              </div>
              <div className="tutorial-info-block">
                <h3><AlertTriangle size={18} /> Important</h3>
                <p>Le permis de conduire est <strong>obligatoire</strong> pour conduire légalement. Vous devrez passer un examen théorique puis pratique.</p>
              </div>
            </div>
          ),
          actions: [
            { label: 'Continuer (fermer la tablette)', action: 'releaseControls', icon: <ChevronRight size={16} />, variant: 'primary' },
          ],
        };

      // ==================== DRIVESCHOOL ACTIVE ====================
      case 'driveschool_active':
        return {
          title: 'Examen en cours',
          subtitle: 'Suivez les instructions',
          icon: <Car size={28} />,
          progress: 55,
          content: (
            <div className="tutorial-content-section">
              <div className="tutorial-info-block highlight">
                <h3><Car size={18} /> Examen du permis</h3>
                <p>Suivez attentivement les instructions de l'examinateur. Respectez le code de la route et les limitations de vitesse !</p>
              </div>
              <div className="tutorial-loading">
                <div className="tutorial-loading-spinner"></div>
                <p>Examen en cours...</p>
              </div>
            </div>
          ),
          actions: [],
        };

      // ==================== LICENSE DONE ====================
      case 'license_done':
        return {
          title: 'Permis obtenu !',
          subtitle: 'Félicitations',
          icon: <CheckCircle2 size={28} />,
          progress: 60,
          content: (
            <div className="tutorial-content-section">
              <div className="tutorial-info-block highlight">
                <h3><CheckCircle2 size={18} /> Bravo !</h3>
                <p>Vous avez obtenu votre <strong>permis de conduire</strong> ! Vous pouvez maintenant conduire légalement dans la ville.</p>
              </div>
              <div className="tutorial-info-block">
                <h3><Car size={18} /> Votre véhicule gratuit</h3>
                <p>Un véhicule de démarrage vous attend non loin d'ici. Suivez le point GPS et appuyez sur <kbd>E</kbd> pour le récupérer auprès du mécanicien. Il sera <strong>ajouté directement à votre garage</strong> !</p>
              </div>
            </div>
          ),
          actions: [
            { label: 'Récupérer mon véhicule', action: 'continueAfterLicense', icon: <Car size={16} />, variant: 'primary' },
          ],
        };

      // ==================== GOTO VEHICLE PICKUP ====================
      case 'goto_vehicle_pickup':
        return {
          title: 'Récupérer votre véhicule',
          subtitle: 'Suivez le GPS',
          icon: <Car size={28} />,
          progress: 65,
          content: (
            <div className="tutorial-content-section">
              <div className="tutorial-objective">
                <Navigation size={20} />
                <div>
                  <strong>Objectif : Récupérez votre véhicule gratuit</strong>
                  <p>Suivez le marqueur sur votre GPS et appuyez sur <kbd>E</kbd> près du mécanicien pour récupérer votre véhicule.</p>
                </div>
              </div>
            </div>
          ),
          actions: [],
        };

      // ==================== VEHICLE RECEIVED ====================
      case 'vehicle_received':
        return {
          title: 'Véhicule récupéré !',
          subtitle: 'Il est à vous',
          icon: <Car size={28} />,
          progress: 70,
          content: (
            <div className="tutorial-content-section">
              <div className="tutorial-info-block highlight">
                <h3><Car size={18} /> Votre véhicule est prêt !</h3>
                <p>Votre véhicule de démarrage a été <strong>ajouté à votre garage</strong>. Vous en êtes le propriétaire !</p>
              </div>
              <div className="tutorial-info-block">
                <h3><Shirt size={18} /> Prochaine étape : Vêtements</h3>
                <p>Direction le magasin de vêtements pour <strong>personnaliser votre tenue</strong>. Montez dans votre véhicule et suivez le GPS !</p>
              </div>
            </div>
          ),
          actions: [
            { label: 'Aller au magasin de vêtements', action: 'continueAfterVehicle', icon: <Shirt size={16} />, variant: 'primary' },
          ],
        };

      // ==================== GOTO CLOTHING ====================
      case 'goto_clothing':
        return {
          title: 'Magasin de vêtements',
          subtitle: 'Suivez le GPS',
          icon: <Shirt size={28} />,
          progress: 73,
          content: (
            <div className="tutorial-content-section">
              <div className="tutorial-objective">
                <Navigation size={20} />
                <div>
                  <strong>Objectif : Rendez-vous au magasin de vêtements</strong>
                  <p>Suivez le marqueur sur votre GPS. Arrêtez-vous à proximité du magasin.</p>
                </div>
              </div>
            </div>
          ),
          actions: [],
        };

      // ==================== WAITING CLOTHING ====================
      case 'waiting_clothing':
        return {
          title: 'Magasin de vêtements',
          subtitle: 'Personnalisez votre tenue',
          icon: <Shirt size={28} />,
          progress: 75,
          content: (
            <div className="tutorial-content-section">
              <div className="tutorial-info-block highlight">
                <h3><Shirt size={18} /> Changez de tenue</h3>
                <p>Entrez dans le magasin et <strong>choisissez une tenue</strong> qui correspond à votre personnage. Prenez votre temps !</p>
              </div>
              <div className="tutorial-info-block">
                <h3><CheckCircle2 size={18} /> Comment continuer ?</h3>
                <p>Une fois vos achats terminés, appuyez sur <kbd>F</kbd> pour passer à la prochaine étape du tutoriel.</p>
              </div>
            </div>
          ),
          actions: [
            { label: 'Entrer dans le magasin', action: 'enterClothingShop', icon: <ArrowRight size={16} />, variant: 'primary' },
          ],
        };

      // ==================== CLOTHING ACTIVE (F to continue — handled by Lua help text) ====================

      // ==================== CLOTHING DONE ====================
      case 'clothing_done':
        return {
          title: 'Tenue choisie !',
          subtitle: 'Direction le pôle emploi',
          icon: <Shirt size={28} />,
          progress: 80,
          content: (
            <div className="tutorial-content-section">
              <div className="tutorial-info-block highlight">
                <h3><CheckCircle2 size={18} /> Parfait !</h3>
                <p>Votre nouvelle tenue vous va à merveille !</p>
              </div>
              <div className="tutorial-info-block">
                <h3><Briefcase size={18} /> Dernière étape : Le Pôle Emploi</h3>
                <p>Rendez-vous au <strong>pôle emploi</strong> avec votre véhicule pour découvrir les métiers disponibles et choisir celui qui vous correspond. C'est la dernière étape du tutoriel !</p>
              </div>
            </div>
          ),
          actions: [
            { label: 'Aller au pôle emploi', action: 'continueToJobCenter', icon: <Briefcase size={16} />, variant: 'primary' },
          ],
        };

      // ==================== GOTO JOB CENTER ====================
      case 'goto_jobcenter':
        return {
          title: 'Pôle emploi',
          subtitle: 'Suivez le GPS',
          icon: <Briefcase size={28} />,
          progress: 85,
          content: (
            <div className="tutorial-content-section">
              <div className="tutorial-objective">
                <Navigation size={20} />
                <div>
                  <strong>Objectif : Rendez-vous au pôle emploi</strong>
                  <p>Suivez le marqueur sur votre GPS. Arrêtez-vous à proximité.</p>
                </div>
              </div>
            </div>
          ),
          actions: [],
        };

      // ==================== ARRIVED JOB CENTER ====================
      case 'arrived_jobcenter':
        return {
          title: 'Pôle emploi',
          subtitle: 'Choisissez votre premier métier',
          icon: <Briefcase size={28} />,
          progress: 90,
          content: (
            <div className="tutorial-content-section">
              <div className="tutorial-info-block highlight">
                <h3><Briefcase size={18} /> Bienvenue au pôle emploi</h3>
                <p>Entrez dans le bâtiment et <strong>parlez à la dame au comptoir</strong> pour choisir parmi les métiers disponibles :</p>
              </div>
              {jobs.length > 0 && (
                <div className="tutorial-jobs-list">
                  {jobs.map((job, i) => (
                    <div key={i} className="tutorial-job-card">
                      <div className="tutorial-job-header">
                        <Briefcase size={16} />
                        <strong>{job.name}</strong>
                      </div>
                      <p>{job.description}</p>
                    </div>
                  ))}
                </div>
              )}
              <div className="tutorial-info-block">
                <h3><Star size={18} /> Conseil</h3>
                <p>Vous pourrez <strong>changer de métier</strong> à tout moment en revenant ici. Prenez le temps d'explorer les options !</p>
              </div>
            </div>
          ),
          actions: [
            { label: 'Continuer', action: 'nextStep', icon: <ChevronRight size={16} />, variant: 'primary', data: { nextStep: 'tutorial_complete' } },
          ],
        };

      // ==================== TUTORIAL COMPLETE ====================
      case 'tutorial_complete':
        return {
          title: 'Félicitations !',
          subtitle: 'Vous êtes prêt',
          icon: <Trophy size={28} />,
          progress: 100,
          content: (
            <div className="tutorial-complete-page">
              {/* Hero */}
              <div className="tutorial-complete-hero">
                <div className="tutorial-complete-trophy-ring">
                  <div className="tutorial-complete-trophy-glow" />
                  <Trophy size={48} />
                </div>
                <h1>Tutoriel terminé !</h1>
                <p>Vous avez complété toutes les étapes. Votre aventure sur <strong>{serverConfig.serverName || 'le serveur'}</strong> commence maintenant.</p>
              </div>

              {/* Achievements */}
              <div className="tutorial-complete-achievements">
                <div className="tutorial-complete-achievement">
                  <div className="tutorial-complete-achievement-icon">
                    <BookOpen size={18} />
                  </div>
                  <div className="tutorial-complete-achievement-info">
                    <strong>Bases du RP</strong>
                    <span>Maîtrisées</span>
                  </div>
                  <CheckCircle2 size={16} className="tutorial-complete-check" />
                </div>
                <div className="tutorial-complete-achievement">
                  <div className="tutorial-complete-achievement-icon">
                    <Shield size={18} />
                  </div>
                  <div className="tutorial-complete-achievement-info">
                    <strong>Règlement</strong>
                    <span>Consulté</span>
                  </div>
                  <CheckCircle2 size={16} className="tutorial-complete-check" />
                </div>
                <div className="tutorial-complete-achievement">
                  <div className="tutorial-complete-achievement-icon">
                    <Car size={18} />
                  </div>
                  <div className="tutorial-complete-achievement-info">
                    <strong>Permis de conduire</strong>
                    <span>Obtenu</span>
                  </div>
                  <CheckCircle2 size={16} className="tutorial-complete-check" />
                </div>
                <div className="tutorial-complete-achievement">
                  <div className="tutorial-complete-achievement-icon">
                    <Car size={18} />
                  </div>
                  <div className="tutorial-complete-achievement-info">
                    <strong>Véhicule</strong>
                    <span>Récupéré</span>
                  </div>
                  <CheckCircle2 size={16} className="tutorial-complete-check" />
                </div>
                <div className="tutorial-complete-achievement">
                  <div className="tutorial-complete-achievement-icon">
                    <Shirt size={18} />
                  </div>
                  <div className="tutorial-complete-achievement-info">
                    <strong>Tenue</strong>
                    <span>Personnalisée</span>
                  </div>
                  <CheckCircle2 size={16} className="tutorial-complete-check" />
                </div>
                <div className="tutorial-complete-achievement">
                  <div className="tutorial-complete-achievement-icon">
                    <Briefcase size={18} />
                  </div>
                  <div className="tutorial-complete-achievement-info">
                    <strong>Pôle emploi</strong>
                    <span>Découvert</span>
                  </div>
                  <CheckCircle2 size={16} className="tutorial-complete-check" />
                </div>
              </div>

              {/* Next steps */}
              <div className="tutorial-complete-nextsteps">
                <h3><Sparkles size={16} /> Et maintenant ?</h3>
                <div className="tutorial-complete-nextsteps-grid">
                  {path === 'illegal' ? (
                    <>
                      <div className="tutorial-complete-nextstep-card">
                        <Skull size={20} />
                        <div>
                          <strong>Tablette F7</strong>
                          <p>Créez votre organisation criminelle</p>
                        </div>
                      </div>
                      <div className="tutorial-complete-nextstep-card">
                        <Target size={20} />
                        <div>
                          <strong>Missions</strong>
                          <p>Complétez des missions pour monter en niveau</p>
                        </div>
                      </div>
                    </>
                  ) : (
                    <>
                      <div className="tutorial-complete-nextstep-card">
                        <Briefcase size={20} />
                        <div>
                          <strong>Métiers</strong>
                          <p>Explorez les différents métiers disponibles</p>
                        </div>
                      </div>
                      <div className="tutorial-complete-nextstep-card">
                        <Star size={20} />
                        <div>
                          <strong>Progression</strong>
                          <p>Gagnez de l'argent et montez en grade</p>
                        </div>
                      </div>
                    </>
                  )}
                  <div className="tutorial-complete-nextstep-card">
                    <Wrench size={20} />
                    <div>
                      <strong>Mécano</strong>
                      <p>Personnalisez votre véhicule (<kbd>F5</kbd> → Status entreprises)</p>
                    </div>
                  </div>
                  <div className="tutorial-complete-nextstep-card">
                    <MessageSquare size={20} />
                    <div>
                      <strong>Communauté</strong>
                      <p>N'hésitez pas à demander de l'aide au staff</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ),
          actions: [
            { label: 'Commencer l\'aventure !', action: 'complete', icon: <Rocket size={16} />, variant: 'primary' },
          ],
        };

      default:
        return null;
    }
  }, [currentStep, path, discordLink, jobs, handleAction, primaryColor, serverConfig]);

  const stepContent = getStepContent();

  // ============================================================================
  // PROGRESS STEPS FOR SIDEBAR
  // ============================================================================

  const progressSteps = useMemo(() => {
    const base = [
      { id: 'welcome', label: 'Bienvenue', icon: <Sparkles size={16} /> },
      { id: 'categories', label: 'Programme', icon: <BookOpen size={16} /> },
      { id: 'basics_rp', label: 'Bases du RP', icon: <BookOpen size={16} /> },
      { id: 'rules_overview', label: 'Règlement', icon: <Shield size={16} /> },
      { id: 'features_overview', label: 'Fonctionnalités', icon: <Gamepad2 size={16} /> },
      { id: 'choose_path', label: 'Votre voie', icon: <Swords size={16} /> },
    ];

    if (path === 'legal') {
      base.push({ id: 'path_chosen', label: 'Voie Légale', icon: <Scale size={16} /> });
    } else if (path === 'illegal') {
      base.push({ id: 'path_chosen', label: 'Voie Illégale', icon: <Skull size={16} /> });
    }

    base.push(
      { id: 'permis', label: 'Permis', icon: <Car size={16} /> },
      { id: 'vehicle', label: 'Véhicule', icon: <Car size={16} /> },
      { id: 'clothes', label: 'Vêtements', icon: <Shirt size={16} /> },
      { id: 'jobcenter', label: 'Pôle Emploi', icon: <Briefcase size={16} /> },
      { id: 'tutorial_complete', label: 'Terminé', icon: <Trophy size={16} /> },
    );

    return base;
  }, [path]);

  const getStepStatus = useCallback((stepId: string): 'completed' | 'active' | 'pending' => {
    const stepGroups: Record<string, string[]> = {
      'welcome': ['welcome'],
      'categories': ['categories'],
      'basics_rp': ['basics_rp'],
      'rules_overview': ['rules_overview'],
      'features_overview': ['features_overview'],
      'choose_path': ['choose_path'],
      'path_chosen': ['path_chosen'],
      'permis': ['goto_driveschool', 'waiting_driveschool', 'driveschool_active', 'license_done'],
      'vehicle': ['goto_vehicle_pickup', 'vehicle_received'],
      'clothes': ['goto_clothing', 'waiting_clothing', 'clothing_active', 'clothing_done'],
      'jobcenter': ['goto_jobcenter', 'arrived_jobcenter'],
      'tutorial_complete': ['tutorial_complete'],
    };

    const currentGroupIndex = progressSteps.findIndex(s => {
      const group = stepGroups[s.id];
      return group && group.includes(currentStep);
    });

    const thisIndex = progressSteps.findIndex(s => s.id === stepId);

    if (thisIndex < currentGroupIndex) return 'completed';
    if (thisIndex === currentGroupIndex) return 'active';
    return 'pending';
  }, [currentStep, progressSteps]);

  if (!visible) return null;

  return (
    <div className={`tutorial-overlay ${hiding ? 'tutorial-hiding' : ''} ${animating ? 'tutorial-animating' : ''}`}>
      <div className="tutorial-container" style={tutorialAccentVars as React.CSSProperties}>
        {/* Sidebar */}
        <div className="tutorial-sidebar">
          <div className="tutorial-sidebar-header">
            {serverConfig.serverIcon && (
              <img src={serverConfig.serverIcon} alt="" className="tutorial-sidebar-logo" />
            )}
            <div className="tutorial-sidebar-title">
              <h1>{serverConfig.serverName || 'Null'}</h1>
              <p>Tutoriel</p>
            </div>
          </div>

          {/* Progress bar */}
          <div className="tutorial-sidebar-progress">
            <div className="tutorial-sidebar-progress-bar">
              <div
                className="tutorial-sidebar-progress-fill"
                style={{ width: `${stepContent?.progress || 0}%` }}
              />
            </div>
            <span className="tutorial-sidebar-progress-text">{stepContent?.progress || 0}%</span>
          </div>

          {/* Steps */}
          <nav className="tutorial-sidebar-nav">
            {progressSteps.map((step) => {
              const status = getStepStatus(step.id);
              return (
                <div
                  key={step.id}
                  className={`tutorial-sidebar-step ${status}`}
                >
                  {status === 'active' && <div className="tutorial-sidebar-indicator" style={{ background: accentColor }} />}
                  <div className="tutorial-sidebar-step-icon">
                    {status === 'completed' ? <CheckCircle2 size={16} /> : step.icon}
                  </div>
                  <span>{step.label}</span>
                  <ChevronRight size={14} className="tutorial-sidebar-arrow" />
                </div>
              );
            })}
          </nav>

          <div className="tutorial-sidebar-footer">
            <button className="tutorial-skip-btn" onClick={() => handleAction('skip')}>
              <X size={16} />
              <span>Passer le tutoriel</span>
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="tutorial-content">
          {stepContent && (
            <>
              <div className="tutorial-content-header">
                <div className="tutorial-content-header-text">
                  {stepContent.subtitle && <span className="tutorial-content-subtitle">{stepContent.subtitle}</span>}
                  <h2>{stepContent.title}</h2>
                </div>
              </div>

              <div className="tutorial-content-body">
                {stepContent.content}
              </div>

              {stepContent.actions && stepContent.actions.length > 0 && (
                <div className="tutorial-content-actions">
                  {stepContent.actions.map((action, i) => (
                    <button
                      key={i}
                      className={`tutorial-action-btn ${action.variant || 'primary'}`}
                      onClick={() => handleAction(action.action, action.data)}
                    >
                      {action.icon}
                      <span>{action.label}</span>
                    </button>
                  ))}
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default Tutorial;

export interface CharacterCreatorProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
  serverConfig?: {
    serverName: string;
    serverIcon: string;
    serverBackground: string;
  };
}

export interface MaxValues {
  father: number;
  mother: number;
  hairstyle: number;
  hairColor: number;
  eyebrows: number;
  beard: number;
  eyeColor: number;
  beardColor: number;
  eyebrowColor: number;
  lipstickStyle: number;
  lipstickColor: number;
  chestHair: number;
  blemishes: number;
}

export interface CreatorData {
  gender: 'm' | 'f';
  maxValues: MaxValues;
  outfits: Record<string, any>;
}

export type CreatorCategory =
  | 'identity'
  | 'heritage'
  | 'hair'
  | 'face'
  | 'appearance'
  | 'outfits';

export interface ParentInfo {
  name: string;
  index: number;
  image: string;
}

export const FATHER_NAMES = [
  'Benjamin', 'Daniel', 'Joshua', 'Noah', 'Andrew',
  'Juan', 'Alex', 'Isaac', 'Evan', 'Ethan',
  'Vincent', 'Angel', 'Diego', 'Adrian', 'Gabriel',
  'Michael', 'Santiago', 'Kevin', 'Louis', 'Samuel',
  'Anthony', 'Claude', 'Niko', 'John'
];

export const MOTHER_NAMES = [
  'Hannah', 'Audrey', 'Jasmine', 'Giselle', 'Amelia',
  'Isabella', 'Zoe', 'Ava', 'Camila', 'Violet',
  'Sophia', 'Evelyn', 'Nicole', 'Ashley', 'Grace',
  'Brianna', 'Natalie', 'Olivia', 'Avery', 'Elizabeth',
  'Charlotte', 'Emma', 'Misty'
];

export const HERITAGE_IMAGES: Record<string, string> = {
  'Male-Benjamin': 'CharacterCreator-GTAO-Parent-Male-Benjamin-C1CN4zvZ.png',
  'Male-Daniel': 'CharacterCreator-GTAO-Parent-Male-Daniel-BHzM6IXW.png',
  'Male-Joshua': 'CharacterCreator-GTAO-Parent-Male-Joshua-Dkol9-0v.png',
  'Male-Noah': 'CharacterCreator-GTAO-Parent-Male-Noah-Bj1cSF7D.png',
  'Male-Andrew': 'CharacterCreator-GTAO-Parent-Male-Andrew-Cj0N5SMr.png',
  'Male-Juan': 'CharacterCreator-GTAO-Parent-Male-Juan-BHareFhc.png',
  'Male-Alex': 'CharacterCreator-GTAO-Parent-Male-Alex-Bok7s0XD.png',
  'Male-Isaac': 'CharacterCreator-GTAO-Parent-Male-Isaac-D_uV5yGp.png',
  'Male-Evan': 'CharacterCreator-GTAO-Parent-Male-Evan-DQiBrDeu.png',
  'Male-Ethan': 'CharacterCreator-GTAO-Parent-Male-Ethan-ibukmW9T.png',
  'Male-Vincent': 'CharacterCreator-GTAO-Parent-Male-Vincent-uDhbkPgI.png',
  'Male-Angel': 'CharacterCreator-GTAO-Parent-Male-Angel-dhRSJSTv.png',
  'Male-Diego': 'CharacterCreator-GTAO-Parent-Male-Diego-DuGYmLdN.png',
  'Male-Adrian': 'CharacterCreator-GTAO-Parent-Male-Adrian-CSzS7KUi.png',
  'Male-Gabriel': 'CharacterCreator-GTAO-Parent-Male-Gabriel-BKzqh_xd.png',
  'Male-Michael': 'CharacterCreator-GTAO-Parent-Male-Michael-DDbXVQ2L.png',
  'Male-Santiago': 'CharacterCreator-GTAO-Parent-Male-Santiago-hqWmHXQb.png',
  'Male-Kevin': 'CharacterCreator-GTAO-Parent-Male-Kevin-DYDxO4Si.png',
  'Male-Louis': 'CharacterCreator-GTAO-Parent-Male-Louis-BFxkSGS0.png',
  'Male-Samuel': 'CharacterCreator-GTAO-Parent-Male-Samuel-CrDxS97X.png',
  'Male-Anthony': 'CharacterCreator-GTAO-Parent-Male-Anthony-BFTI4PDs.png',
  'Male-Claude': 'CharacterCreator-GTAO-Parent-Male-Claude-DIKAgmXk.png',
  'Male-Niko': 'CharacterCreator-GTAO-Parent-Male-Niko-CC1a4mep.png',
  'Male-John': 'CharacterCreator-GTAO-Parent-Male-John-CpCfz2Ey.png',
  'Female-Hannah': 'CharacterCreator-GTAO-Parent-Female-Hannah-B6yFivh8.png',
  'Female-Audrey': 'CharacterCreator-GTAO-Parent-Female-Audrey-B6u_8ume.png',
  'Female-Jasmine': 'CharacterCreator-GTAO-Parent-Female-Jasmine-DYeuHw8V.png',
  'Female-Giselle': 'CharacterCreator-GTAO-Parent-Female-Giselle-BOMc0mWW.png',
  'Female-Amelia': 'CharacterCreator-GTAO-Parent-Female-Amelia-CZFWXTO2.png',
  'Female-Isabella': 'CharacterCreator-GTAO-Parent-Female-Isabella-DWpUCbBa.png',
  'Female-Zoe': 'CharacterCreator-GTAO-Parent-Female-Zoe-CarTP6Jt.png',
  'Female-Ava': 'CharacterCreator-GTAO-Parent-Female-Ava-BHNcd7Sk.png',
  'Female-Camila': 'CharacterCreator-GTAO-Parent-Female-Camila-PLwPW9HL.png',
  'Female-Violet': 'CharacterCreator-GTAO-Parent-Female-Violet-CCkWvSjr.png',
  'Female-Sophia': 'CharacterCreator-GTAO-Parent-Female-Sophia-B5GPRRdP.png',
  'Female-Evelyn': 'CharacterCreator-GTAO-Parent-Female-Evelyn-DT7PStFk.png',
  'Female-Nicole': 'CharacterCreator-GTAO-Parent-Female-Nicole-DIs67_JI.png',
  'Female-Ashley': 'CharacterCreator-GTAO-Parent-Female-Ashley-DNtz2M4Y.png',
  'Female-Grace': 'CharacterCreator-GTAO-Parent-Female-Grace-C5hsdwN8.png',
  'Female-Brianna': 'CharacterCreator-GTAO-Parent-Female-Brianna-Bg3-hTMU.png',
  'Female-Natalie': 'CharacterCreator-GTAO-Parent-Female-Natalie-CZP5GtIX.png',
  'Female-Olivia': 'CharacterCreator-GTAO-Parent-Female-Olivia-ChV1ttn9.png',
  'Female-Avery': '',
  'Female-Elizabeth': 'CharacterCreator-GTAO-Parent-Female-Elizabeth-B7-qIrOq.png',
  'Female-Charlotte': 'CharacterCreator-GTAO-Parent-Female-Charlotte-dYcKWPaI.png',
  'Female-Emma': 'CharacterCreator-GTAO-Parent-Female-Emma-muOrblXv.png',
  'Female-Misty': 'CharacterCreator-GTAO-Parent-Female-Misty-Cpy7Nvuu.png',
};

export const GTA_HAIR_COLORS = [
  '#18191A', '#2B2622', '#5A5751', '#FFFCF1', '#E5C5A5', '#DEB7A5',
  '#C5A587', '#B18C6A', '#A37453', '#8C6342', '#6F4E37', '#4A3728',
  '#3B2F2F', '#1B1B1B', '#1C1C1C', '#1F1F1F', '#2C2C2C', '#3A3A3A',
  '#4A4A4A', '#5C5C5C', '#6E6E6E', '#808080', '#929292', '#A4A4A4',
  '#B6B6B6', '#C8C8C8', '#DADADA', '#ECECEC', '#8B4513', '#A0522D',
  '#CD853F', '#DEB887', '#F4A460', '#D2691E', '#8B0000', '#A52A2A',
  '#B22222', '#DC143C', '#FF0000', '#FF6347', '#FF7F50', '#FFA07A',
  '#E9967A', '#FA8072', '#FFC0CB', '#FFB6C1', '#FF69B4', '#FF1493',
  '#C71585', '#DB7093', '#8B008B', '#9370DB', '#8A2BE2', '#9400D3',
  '#9932CC', '#BA55D3', '#DA70D6', '#EE82EE', '#DDA0DD', '#D8BFD8',
  '#4B0082', '#483D8B'
];

export const EYE_COLORS = [
  '#789018',
  '#249b80',
  '#5aa5ef',
  '#257ad8',
  '#dc872e',
  '#6c3f35',
  '#9d8165',
  '#676977',
  '#bec4d5',
  '#e55b99',
  '#e6a91b',
  '#5845e1',
  '#111319',
  '#6989b3',
  '#f3b310',
  '#2de019',
  '#5d761d',
  '#25c8d4',
  '#b8d7ec',
  '#173a9c',
  '#bd850d',
  '#3e2218',
  '#d2d3df',
  '#df7d1b',
  'radial-gradient(circle, #111319 0 18%, #789018 20% 100%)',
  'radial-gradient(circle, #111319 0 18%, #249b80 20% 100%)',
  'radial-gradient(circle, #111319 0 18%, #5aa5ef 20% 100%)',
  'radial-gradient(circle, #111319 0 18%, #257ad8 20% 100%)',
  'radial-gradient(circle, #111319 0 18%, #dc872e 20% 100%)',
  'radial-gradient(circle, #111319 0 18%, #d2d3df 20% 100%)'
];

export interface FaceSliderDef {
  key: string;
  label: string;
  min: number;
  max: number;
  step: number;
  defaultValue: number;
}

export const FACE_SLIDERS: FaceSliderDef[] = [
  { key: 'noseWidth', label: 'Largeur du nez', min: -100, max: 100, step: 1, defaultValue: 0 },
  { key: 'noseHeight', label: 'Hauteur du nez', min: -100, max: 100, step: 1, defaultValue: 0 },
  { key: 'noseLength', label: 'Longueur du nez', min: -100, max: 100, step: 1, defaultValue: 0 },
  { key: 'noseBase', label: 'Base du nez', min: -100, max: 100, step: 1, defaultValue: 0 },
  { key: 'noseRotation', label: 'Rotation du nez', min: -100, max: 100, step: 1, defaultValue: 0 },
  { key: 'cheekBones', label: 'Pommettes', min: -100, max: 100, step: 1, defaultValue: 0 },
  { key: 'eyeOpenness', label: 'Ouverture des yeux', min: -100, max: 100, step: 1, defaultValue: 0 },
  { key: 'lipThickness', label: 'Épaisseur des lèvres', min: -100, max: 100, step: 1, defaultValue: 0 },
  { key: 'chinHeight', label: 'Hauteur du menton', min: -100, max: 100, step: 1, defaultValue: 0 },
  { key: 'chinLength', label: 'Longueur du menton', min: -100, max: 100, step: 1, defaultValue: 0 },
  { key: 'chinWidth', label: 'Largeur du menton', min: -100, max: 100, step: 1, defaultValue: 0 },
  { key: 'neckThickness', label: 'Épaisseur du cou', min: -100, max: 100, step: 1, defaultValue: 0 },
];

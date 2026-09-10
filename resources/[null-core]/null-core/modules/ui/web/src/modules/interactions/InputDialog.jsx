import React, { useState, useEffect, useRef } from 'react';
import './styles/InputDialog.css';
import { soundManager } from '@core/SoundManager';
import { hudPositionManager } from '../../utils/hudPositionManager';
import { applyAnchorPosition } from '../../utils/anchorPositioning';
import { X, Check, AlertCircle, ChevronDown, Calendar, Clock, Pipette } from 'lucide-react';

function InputDialog({ visible, data, onClose, serverConfig, primaryColor, previewMode = false, previewPosition = null, hudEditorOpen = false }) {
  
  const isVisible = previewMode || visible;
  const dialogData = previewMode ? {
    title: 'Saisie',
    fields: [
      { label: 'Nom', type: 'text', placeholder: 'Entrez votre nom', default: '' },
      { label: 'Montant', type: 'number', placeholder: '0', default: '' }
    ]
  } : data;
  const [inputs, setInputs] = useState({});
  const [actualPosition, setActualPosition] = useState(null);
  
  // Load saved position
  useEffect(() => {
    if (previewMode) return;
    
    hudPositionManager.onReady(() => {
      const savedPos = hudPositionManager.getPosition('input_dialog');
      if (savedPos) {
        setActualPosition(savedPos);
      } 
    });
  }, [previewMode]);
  const [errors, setErrors] = useState({});
  const [multiSelectOpen, setMultiSelectOpen] = useState({});
  const [multiSelectSearch, setMultiSelectSearch] = useState({});
  const [colorPickerOpen, setColorPickerOpen] = useState({});
  const inputRefs = useRef({});

  const getFieldDefault = (field) => {
    switch (field.type) {
      case 'checkbox':
        return field.checked || field.default || false;
      case 'multi-select':
        return field.default || [];
      case 'slider':
        return field.default ?? field.min ?? 0;
      case 'color':
        return field.default || '#ffffff';
      case 'date':
        if (field.default === true) return new Date().toISOString().split('T')[0];
        return field.default || '';
      case 'date-range':
        if (field.default && Array.isArray(field.default)) return field.default;
        return ['', ''];
      case 'time':
        return field.default || '';
      default:
        return field.default || '';
    }
  };

  useEffect(() => {
    if (visible && dialogData?.fields && !previewMode) {
      const initialValues = {};
      data.fields.forEach((field, index) => {
        initialValues[index] = getFieldDefault(field);
      });
      setInputs(initialValues);
      setErrors({});

      // Auto-focus first focusable input with multiple retries for CEF
      const focusFirst = (retries = 0) => {
        const el = inputRefs.current[0];
        if (el && typeof el.focus === 'function') {
          el.focus();
          // For text/number inputs, also place cursor at end
          if (el.tagName === 'INPUT' && (el.type === 'text' || el.type === 'number' || el.type === 'password')) {
            try { el.select(); } catch (_) {}
          }
          // Verify focus actually took; retry if not
          if (retries < 5 && document.activeElement !== el) {
            setTimeout(() => focusFirst(retries + 1), 80);
          }
        } else if (retries < 5) {
          setTimeout(() => focusFirst(retries + 1), 80);
        }
      };
      setTimeout(() => focusFirst(), 50);
    } else if (previewMode && dialogData?.fields) {
      const initialValues = {};
      dialogData.fields.forEach((field, index) => {
        initialValues[index] = getFieldDefault(field);
      });
      setInputs(initialValues);
    }
  }, [visible, dialogData, previewMode]);

  useEffect(() => {
    if (!visible || previewMode) return;

    const handleKeyDown = (e) => {
      if (e.key === 'Escape') {
        handleCancel();
      } else if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        handleSubmit();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [visible, inputs]);

  const handleInputChange = (index, value) => {
    setInputs(prev => ({ ...prev, [index]: value }));
    if (errors[index]) {
      setErrors(prev => {
        const newErrors = { ...prev };
        delete newErrors[index];
        return newErrors;
      });
    }
  };

  const validateInputs = () => {
    const newErrors = {};
    let isValid = true;

    data.fields.forEach((field, index) => {
      const value = inputs[index];

      // Required check per type
      if (field.required) {
        if (field.type === 'multi-select') {
          if (!value || !Array.isArray(value) || value.length === 0) {
            newErrors[index] = 'Ce champ est requis';
            isValid = false;
            return;
          }
        } else if (field.type === 'date-range') {
          if (!value || !value[0] || !value[1]) {
            newErrors[index] = 'Les deux dates sont requises';
            isValid = false;
            return;
          }
        } else if (field.type === 'checkbox') {
          if (value !== true && value !== 'true') {
            newErrors[index] = 'Ce champ est requis';
            isValid = false;
            return;
          }
        } else if (field.type === 'slider') {
          // slider always has a value, skip
        } else if (field.type === 'color') {
          if (!value || value.trim() === '') {
            newErrors[index] = 'Ce champ est requis';
            isValid = false;
            return;
          }
        } else if (!value || value.toString().trim() === '') {
          newErrors[index] = 'Ce champ est requis';
          isValid = false;
          return;
        }
      }

      // Type-specific validation
      switch (field.type) {
        case 'number':
        case 'slider': {
          const num = parseFloat(value);
          if (value !== '' && value !== undefined) {
            if (isNaN(num)) {
              newErrors[index] = 'Doit être un nombre';
              isValid = false;
            } else {
              if (field.min !== undefined && num < field.min) {
                newErrors[index] = `Minimum: ${field.min}`;
                isValid = false;
              }
              if (field.max !== undefined && num > field.max) {
                newErrors[index] = `Maximum: ${field.max}`;
                isValid = false;
              }
            }
          }
          break;
        }
        case 'multi-select':
          if (field.maxSelectedValues && Array.isArray(value) && value.length > field.maxSelectedValues) {
            newErrors[index] = `Maximum ${field.maxSelectedValues} sélections`;
            isValid = false;
          }
          break;

        case 'textarea':
          if (value) {
            if (field.maxLength && value.length > field.maxLength) {
              newErrors[index] = `Maximum ${field.maxLength} caractères`;
              isValid = false;
            }
            if (field.minLength && value.length < field.minLength) {
              newErrors[index] = `Minimum ${field.minLength} caractères`;
              isValid = false;
            }
          }
          break;

        case 'color':
          if (value && !/^#([0-9a-fA-F]{3,8})$/.test(value)) {
            newErrors[index] = 'Format de couleur invalide';
            isValid = false;
          }
          break;

        case 'input':
        default:
          if (value && value.toString().trim() !== '') {
            if (field.max && value.length > field.max) {
              newErrors[index] = `Maximum ${field.max} caractères`;
              isValid = false;
            }
          }
          break;
      }
    });

    setErrors(newErrors);
    return isValid;
  };

  const formatDateString = (date, format) => {
    const dd = String(date.getDate()).padStart(2, '0');
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    const yyyy = String(date.getFullYear());
    return format.replace('DD', dd).replace('MM', mm).replace('YYYY', yyyy);
  };

  const toggleMultiSelectOption = (index, optionValue, field) => {
    const current = Array.isArray(inputs[index]) ? [...inputs[index]] : [];
    const idx = current.indexOf(optionValue);
    if (idx > -1) {
      current.splice(idx, 1);
    } else {
      if (field.maxSelectedValues && current.length >= field.maxSelectedValues) return;
      current.push(optionValue);
    }
    handleInputChange(index, current);
  };

  const handleSubmit = () => {
    if (!validateInputs()) {
      return;
    }

    const result = data.fields.map((field, index) => {
      const value = inputs[index];
      
      switch (field.type) {
        case 'number':
          return value !== '' && value !== undefined ? parseFloat(value) : null;
        case 'checkbox':
          return value === true || value === 'true';
        case 'select':
          return value || null;
        case 'multi-select':
          return Array.isArray(value) ? value : [];
        case 'slider':
          return typeof value === 'number' ? value : parseFloat(value) || 0;
        case 'color':
          return value || null;
        case 'date': {
          if (!value) return null;
          if (field.returnString) {
            const d = new Date(value);
            const fmt = field.format || 'DD/MM/YYYY';
            return formatDateString(d, fmt);
          }
          return Math.floor(new Date(value).getTime() / 1000);
        }
        case 'date-range': {
          if (!value || !value[0] || !value[1]) return null;
          if (field.returnString) {
            const fmt = field.format || 'DD/MM/YYYY';
            return [formatDateString(new Date(value[0]), fmt), formatDateString(new Date(value[1]), fmt)];
          }
          return [Math.floor(new Date(value[0]).getTime() / 1000), Math.floor(new Date(value[1]).getTime() / 1000)];
        }
        case 'time': {
          if (!value) return null;
          const [h, m] = value.split(':').map(Number);
          return h * 3600 + m * 60;
        }
        default:
          return value || null;
      }
    });

    fetch(`https://${GetParentResourceName()}/inputDialogSubmit`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ values: result })
    });

    soundManager.play('success');
    onClose();
  };

  const handleCancel = () => {
    soundManager.play('back');
    fetch(`https://${GetParentResourceName()}/inputDialogCancel`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });

    onClose();
  };

  if (!isVisible || !dialogData) {
    return null;
  }

  const actualPrimaryColor = primaryColor || serverConfig?.serverColor || '#646464';
  
  // Box shadow for submit button
  const buttonShadow = `0 4px 15px ${actualPrimaryColor}40`;

  // Auto-detect size: if multi-select or date-range fields exist, default to 'lg'
  const hasWideFields = dialogData.fields?.some(f => f.type === 'multi-select' || f.type === 'date-range' || f.type === 'color');
  const dialogSize = dialogData.options?.size || dialogData.size || (hasWideFields ? 'lg' : 'md');

  return (
    <div className={`input-dialog-overlay ${isVisible ? 'visible' : 'hiding'}`} style={{
        display: (hudEditorOpen && !previewMode) ? 'none' : undefined,
        ...(previewMode ? {
          position: 'relative',
          left: 0,
          top: 0,
          transform: 'none'
        } : actualPosition?.anchor ? applyAnchorPosition({
          anchor: actualPosition.anchor,
          position: { x: actualPosition.x, y: actualPosition.y }
        }) : {})
      }}>
      <div 
        className={`input-dialog-container input-dialog-size-${dialogSize}`}
        // style={{ borderBottom: `2px solid ${actualPrimaryColor}` }}
      >
        <div className="input-dialog-header">
          <div className="input-dialog-header-left">
            {/* {serverConfig?.serverIcon && (
              <img src={serverConfig.serverIcon} alt="" className="server-icon" />
            )} */}
            <div className="input-dialog-title-container">
              {serverConfig?.serverName && (
                <span className="server-name">{serverConfig.serverName}</span>
              )}
              <div className="input-dialog-title">
                {dialogData.title || 'Saisie'}
              </div>
            </div>
          </div>
        </div>

        <div className="input-dialog-content">
          <div className="input-dialog-fields">
            {dialogData.fields?.map((field, index) => (
              <div key={index} className="input-dialog-field">
                <label className="input-dialog-label">
                  {field.icon && <i className={field.icon} style={{ marginRight: '8px', opacity: 0.7 }}></i>}
                  {field.label}
                  {field.required && <span className="input-required">*</span>}
                </label>

                {field.description && (
                  <div className="input-dialog-description">{field.description}</div>
                )}

                {field.type === 'select' ? (
                  <select
                    ref={el => inputRefs.current[index] = el}
                    className={`input-dialog-select ${errors[index] ? 'error' : ''}`}
                    value={inputs[index] || ''}
                    onChange={(e) => handleInputChange(index, e.target.value)}
                    style={{ 
                      borderColor: errors[index] ? '#ef4444' : 'var(--bg-tertiary)',
                      ':focus': { borderColor: actualPrimaryColor }
                    }}
                  >
                    <option value="">Sélectionner...</option>
                    {field.options && field.options.map((option, optIndex) => (
                      <option key={optIndex} value={option.value || option}>
                        {option.label || option}
                      </option>
                    ))}
                  </select>
                ) : field.type === 'textarea' ? (
                  <textarea
                    ref={el => inputRefs.current[index] = el}
                    className={`input-dialog-textarea ${errors[index] ? 'error' : ''}`}
                    placeholder={field.placeholder || ''}
                    value={inputs[index] || ''}
                    onChange={(e) => handleInputChange(index, e.target.value)}
                    rows={field.rows || 4}
                    style={{ borderColor: errors[index] ? '#ef4444' : 'var(--bg-tertiary)' }}
                  />
                ) : field.type === 'checkbox' ? (
                  <label className="input-dialog-checkbox">
                    <input
                      ref={el => inputRefs.current[index] = el}
                      type="checkbox"
                      checked={inputs[index] === true || inputs[index] === 'true'}
                      style={{display:"none"}}
                      onChange={(e) => handleInputChange(index, e.target.checked)}
                    />
                    <span 
                      className="checkbox-custom" 
                      style={{ 
                        borderColor: (inputs[index] === true || inputs[index] === 'true') ? actualPrimaryColor : 'var(--text-tertiary)',
                        backgroundColor: (inputs[index] === true || inputs[index] === 'true') ? `${actualPrimaryColor}20` : 'transparent'
                      }}
                    >
                      {(inputs[index] === true || inputs[index] === 'true') && (
                        <Check size={12} color={actualPrimaryColor} strokeWidth={4} />
                      )}
                    </span>
                    <span className="checkbox-label">{field.checkboxLabel || 'Activer'}</span>
                  </label>

                ) : field.type === 'multi-select' ? (
                  <div className="input-dialog-multiselect" ref={el => inputRefs.current[index] = el}>
                    <div
                      className={`input-dialog-multiselect-trigger ${errors[index] ? 'error' : ''}`}
                      onClick={() => setMultiSelectOpen(prev => ({ ...prev, [index]: !prev[index] }))}
                      style={{ borderColor: errors[index] ? '#ef4444' : 'var(--bg-tertiary)' }}
                    >
                      <div className="input-dialog-multiselect-values">
                        {Array.isArray(inputs[index]) && inputs[index].length > 0 ? (
                          inputs[index].map((val, vi) => {
                            const opt = field.options?.find(o => (o.value || o) === val);
                            return (
                              <span key={vi} className="input-dialog-multiselect-tag" style={{ backgroundColor: `${actualPrimaryColor}20`, borderColor: `${actualPrimaryColor}40` }}>
                                {opt?.label || opt || val}
                                <X size={10} onClick={(e) => { e.stopPropagation(); toggleMultiSelectOption(index, val, field); }} />
                              </span>
                            );
                          })
                        ) : (
                          <span className="input-dialog-multiselect-placeholder">{field.placeholder || 'Sélectionner...'}</span>
                        )}
                      </div>
                      <ChevronDown size={14} className={`input-dialog-multiselect-chevron ${multiSelectOpen[index] ? 'open' : ''}`} />
                    </div>
                    {multiSelectOpen[index] && (
                      <div className="input-dialog-multiselect-dropdown">
                        {field.searchable && (
                          <input
                            type="text"
                            className="input-dialog-multiselect-search"
                            placeholder="Rechercher..."
                            value={multiSelectSearch[index] || ''}
                            onChange={(e) => setMultiSelectSearch(prev => ({ ...prev, [index]: e.target.value }))}
                            onClick={(e) => e.stopPropagation()}
                            onMouseDown={(e) => e.stopPropagation()}
                            autoFocus
                          />
                        )}
                        {field.options?.filter(opt => {
                          if (!field.searchable || !multiSelectSearch[index]) return true;
                          const search = multiSelectSearch[index].toLowerCase();
                          const label = (opt.label || opt).toString().toLowerCase();
                          const value = (opt.value || opt).toString().toLowerCase();
                          return label.includes(search) || value.includes(search);
                        }).map((option, optIndex) => {
                          const optValue = option.value || option;
                          const optLabel = option.label || option;
                          const isSelected = Array.isArray(inputs[index]) && inputs[index].includes(optValue);
                          return (
                            <div
                              key={optIndex}
                              className={`input-dialog-multiselect-option ${isSelected ? 'selected' : ''}`}
                              onClick={() => toggleMultiSelectOption(index, optValue, field)}
                            >
                              <span className="input-dialog-multiselect-check" style={{
                                borderColor: isSelected ? actualPrimaryColor : 'var(--text-tertiary)',
                                backgroundColor: isSelected ? `${actualPrimaryColor}20` : 'transparent'
                              }}>
                                {isSelected && <Check size={10} color={actualPrimaryColor} strokeWidth={4} />}
                              </span>
                              {optLabel}
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>

                ) : field.type === 'slider' ? (
                  <div className="input-dialog-slider" ref={el => inputRefs.current[index] = el}>
                    <input
                      type="range"
                      className="input-dialog-slider-input"
                      min={field.min ?? 0}
                      max={field.max ?? 100}
                      step={field.step ?? 1}
                      value={inputs[index] ?? field.min ?? 0}
                      onChange={(e) => handleInputChange(index, parseFloat(e.target.value))}
                      disabled={field.disabled || previewMode}
                      style={{
                        '--slider-progress': `${((inputs[index] - (field.min ?? 0)) / ((field.max ?? 100) - (field.min ?? 0))) * 100}%`,
                        '--slider-color': actualPrimaryColor
                      }}
                    />
                    <span className="input-dialog-slider-value" style={{ color: actualPrimaryColor }}>
                      {inputs[index] ?? field.min ?? 0}
                    </span>
                  </div>

                ) : field.type === 'color' ? (
                  <div className="input-dialog-color" ref={el => inputRefs.current[index] = el}>
                    <div
                      className="input-dialog-color-preview"
                      style={{ backgroundColor: inputs[index] || '#ffffff' }}
                      onClick={() => setColorPickerOpen(prev => ({ ...prev, [index]: !prev[index] }))}
                    />
                    <input
                      type="text"
                      className={`input-dialog-input input-dialog-color-input ${errors[index] ? 'error' : ''}`}
                      value={inputs[index] || ''}
                      onChange={(e) => handleInputChange(index, e.target.value)}
                      placeholder={field.placeholder || '#ffffff'}
                      disabled={field.disabled || previewMode}
                      style={{ borderColor: errors[index] ? '#ef4444' : 'var(--bg-tertiary)' }}
                    />
                    {colorPickerOpen[index] && (
                      <div className="input-dialog-color-picker">
                        <input
                          type="color"
                          value={inputs[index] || '#ffffff'}
                          onChange={(e) => handleInputChange(index, e.target.value)}
                        />
                      </div>
                    )}
                  </div>

                ) : field.type === 'date' ? (
                  <div className="input-dialog-date">
                    <Calendar size={14} className="input-dialog-date-icon" />
                    <input
                      ref={el => inputRefs.current[index] = el}
                      type="date"
                      className={`input-dialog-input input-dialog-date-input ${errors[index] ? 'error' : ''}`}
                      value={inputs[index] || ''}
                      onChange={(e) => handleInputChange(index, e.target.value)}
                      min={field.min}
                      max={field.max}
                      disabled={field.disabled || previewMode}
                      style={{ borderColor: errors[index] ? '#ef4444' : 'var(--bg-tertiary)' }}
                    />
                    {field.clearable && inputs[index] && (
                      <X size={14} className="input-dialog-date-clear" onClick={() => handleInputChange(index, '')} />
                    )}
                  </div>

                ) : field.type === 'date-range' ? (
                  <div className="input-dialog-daterange">
                    <div className="input-dialog-date">
                      <Calendar size={14} className="input-dialog-date-icon" />
                      <input
                        ref={el => inputRefs.current[index] = el}
                        type="date"
                        className={`input-dialog-input input-dialog-date-input ${errors[index] ? 'error' : ''}`}
                        value={(inputs[index] && inputs[index][0]) || ''}
                        onChange={(e) => {
                          const current = inputs[index] || ['', ''];
                          handleInputChange(index, [e.target.value, current[1]]);
                        }}
                        disabled={field.disabled || previewMode}
                        style={{ borderColor: errors[index] ? '#ef4444' : 'var(--bg-tertiary)' }}
                      />
                    </div>
                    <span className="input-dialog-daterange-separator">→</span>
                    <div className="input-dialog-date">
                      <Calendar size={14} className="input-dialog-date-icon" />
                      <input
                        type="date"
                        className={`input-dialog-input input-dialog-date-input ${errors[index] ? 'error' : ''}`}
                        value={(inputs[index] && inputs[index][1]) || ''}
                        onChange={(e) => {
                          const current = inputs[index] || ['', ''];
                          handleInputChange(index, [current[0], e.target.value]);
                        }}
                        disabled={field.disabled || previewMode}
                        style={{ borderColor: errors[index] ? '#ef4444' : 'var(--bg-tertiary)' }}
                      />
                    </div>
                    {field.clearable && inputs[index] && (inputs[index][0] || inputs[index][1]) && (
                      <X size={14} className="input-dialog-date-clear" onClick={() => handleInputChange(index, ['', ''])} />
                    )}
                  </div>

                ) : field.type === 'time' ? (
                  <div className="input-dialog-date">
                    <Clock size={14} className="input-dialog-date-icon" />
                    <input
                      ref={el => inputRefs.current[index] = el}
                      type="time"
                      className={`input-dialog-input input-dialog-date-input ${errors[index] ? 'error' : ''}`}
                      value={inputs[index] || ''}
                      onChange={(e) => handleInputChange(index, e.target.value)}
                      disabled={field.disabled || previewMode}
                      style={{ borderColor: errors[index] ? '#ef4444' : 'var(--bg-tertiary)' }}
                    />
                    {field.clearable && inputs[index] && (
                      <X size={14} className="input-dialog-date-clear" onClick={() => handleInputChange(index, '')} />
                    )}
                  </div>

                ) : (
                  <input
                    ref={el => inputRefs.current[index] = el}
                    type={field.type === 'number' ? 'number' : field.password ? 'password' : 'text'}
                    className={`input-dialog-input ${errors[index] ? 'error' : ''}`}
                    placeholder={field.placeholder || ''}
                    value={inputs[index] || ''}
                    onChange={(e) => handleInputChange(index, e.target.value)}
                    disabled={field.disabled || previewMode}
                    min={field.min}
                    max={field.max}
                    step={field.type === 'number' ? (field.step || 1) : undefined}
                    style={{ borderColor: errors[index] ? '#ef4444' : 'var(--bg-tertiary)' }}
                  />
                )}

                {errors[index] && (
                  <div className="input-dialog-error">
                    <AlertCircle size={14} />
                    <span>{errors[index]}</span>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        <div className="input-dialog-footer">
          <button 
            className="input-dialog-button cancel" 
            onClick={previewMode ? undefined : handleCancel}
            onMouseEnter={() => !previewMode && soundManager.play('hover')}
            disabled={previewMode}
          >
            Annuler
          </button>
          <button 
            className="input-dialog-button submit" 
            onClick={previewMode ? undefined : handleSubmit}
            onMouseEnter={() => !previewMode && soundManager.play('hover')}
            disabled={previewMode}
            style={{ 
              backgroundColor: actualPrimaryColor,
              boxShadow: buttonShadow
            }}
          >
            Valider
          </button>
        </div>
      </div>
    </div>
  );
}

function GetParentResourceName() {
  return window.GetParentResourceName ? window.GetParentResourceName() : 'null-core';
}

export default InputDialog;

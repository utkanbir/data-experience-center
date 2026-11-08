import React from 'react';
import {createRoot} from 'react-dom/client';
import Center from './components/center';
import './styles.css';
createRoot(document.getElementById('root')!).render(<React.StrictMode><Center/></React.StrictMode>);

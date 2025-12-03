import React, { useState, useEffect } from 'react';
import { ArrowRight, Play, Youtube, Cpu, Code2, Workflow, Zap, Menu, X, ChevronRight, Terminal, Bot } from 'lucide-react';

// --- Components ---

const Navbar = () => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <nav 
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        isScrolled ? 'bg-white/80 backdrop-blur-md border-b border-gray-100 py-4' : 'bg-transparent py-6'
      }`}
    >
      <div className="max-w-7xl mx-auto px-6 flex justify-between items-center">
        <div className="text-2xl font-semibold tracking-tight text-gray-900 flex items-center gap-2">
          Alex<span className="text-gray-400">.ai</span>
        </div>
        
        {/* Desktop Menu */}
        <div className="hidden md:flex space-x-8 text-sm font-medium text-gray-500">
          <a href="#content" className="hover:text-gray-900 transition-colors">Content</a>
          <a href="#automation" className="hover:text-gray-900 transition-colors">Automation</a>
          <a href="#consulting" className="hover:text-gray-900 transition-colors">Consulting</a>
        </div>

        <div className="hidden md:block">
          <button className="bg-black text-white px-5 py-2 rounded-full text-sm font-medium hover:bg-gray-800 transition-all transform hover:scale-105 active:scale-95 shadow-lg shadow-gray-200">
            Get in Touch
          </button>
        </div>

        {/* Mobile Toggle */}
        <button 
          className="md:hidden text-gray-900"
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
        >
          {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
      </div>

      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <div className="absolute top-full left-0 right-0 bg-white border-b border-gray-100 p-6 md:hidden flex flex-col space-y-4 shadow-xl">
          <a href="#content" className="text-lg font-medium text-gray-900">Content</a>
          <a href="#automation" className="text-lg font-medium text-gray-900">Automation</a>
          <a href="#consulting" className="text-lg font-medium text-gray-900">Consulting</a>
          <button className="bg-black text-white px-5 py-3 rounded-full text-sm font-medium w-full mt-4">
            Get in Touch
          </button>
        </div>
      )}
    </nav>
  );
};

const FloatingCard = ({ className, delay = 0, children }) => (
  <div 
    className={`absolute hidden lg:block bg-white/40 backdrop-blur-xl border border-white/50 shadow-[0_20px_40px_-15px_rgba(0,0,0,0.1)] rounded-2xl p-4 animate-float ${className}`}
    style={{ animationDelay: `${delay}s` }}
  >
    {children}
  </div>
);

const Hero = () => {
  return (
    <section className="relative pt-32 pb-20 lg:pt-48 lg:pb-32 overflow-hidden">
      <div className="max-w-7xl mx-auto px-6 relative z-10 flex flex-col items-center text-center">
        
        {/* Badge */}
        <div className="inline-flex items-center space-x-2 bg-gray-100/80 backdrop-blur-sm border border-gray-200 px-3 py-1 rounded-full mb-8 animate-fade-in-up">
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
          </span>
          <span className="text-[10px] uppercase tracking-wider font-semibold text-gray-600">New Video: Claude 3.5 Opus Workflow</span>
        </div>

        {/* Headline */}
        <h1 className="text-5xl md:text-7xl lg:text-8xl font-semibold text-gray-900 tracking-tight mb-8 max-w-5xl mx-auto leading-[1.1] animate-fade-in-up delay-100">
          Building the future with <span className="text-gray-400">AI & Automation.</span>
        </h1>

        {/* Subhead */}
        <p className="text-lg md:text-xl text-gray-500 max-w-2xl mx-auto mb-10 leading-relaxed animate-fade-in-up delay-200">
          I help developers and creators master Claude Code, build n8n workflows, and automate the boring stuff so you can focus on creating.
        </p>

        {/* CTAs */}
        <div className="flex flex-col sm:flex-row items-center space-y-4 sm:space-y-0 sm:space-x-4 animate-fade-in-up delay-300">
          <button className="group bg-black text-white h-12 px-8 rounded-full font-medium flex items-center space-x-2 hover:bg-gray-800 transition-all transform hover:scale-105 shadow-xl shadow-gray-200">
            <span>Explore Tutorials</span>
            <Play size={16} fill="currentColor" className="group-hover:translate-x-1 transition-transform" />
          </button>
          <button className="h-12 px-8 rounded-full font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 transition-colors">
            Book Consultation
          </button>
        </div>

      </div>

      {/* Floating Elements (Decorative) */}
      
      {/* Top Left - Code Snippet */}
      <FloatingCard className="top-1/4 left-10 xl:left-32 w-64 bg-gray-900/90 border-gray-700/50 rotate-[-3deg]" delay={0}>
         <div className="font-mono text-[10px] text-gray-300 leading-relaxed">
            <div className="flex gap-2 mb-2 border-b border-gray-700 pb-2">
                <div className="w-2 h-2 rounded-full bg-red-500"></div>
                <div className="w-2 h-2 rounded-full bg-yellow-500"></div>
                <div className="w-2 h-2 rounded-full bg-green-500"></div>
            </div>
            <div className="text-blue-400">const <span className="text-yellow-200">automate</span> = <span className="text-purple-400">async</span> () ={'>'} {'{'}</div>
            <div className="pl-4">await <span className="text-green-300">n8n</span>.trigger();</div>
            <div className="pl-4">return <span className="text-orange-300">"Freedom"</span>;</div>
            <div>{'}'}</div>
         </div>
      </FloatingCard>

      {/* Bottom Right - n8n Node Visual */}
      <FloatingCard className="bottom-20 right-10 xl:right-32 w-auto flex items-center space-x-3 pr-6 rotate-[3deg]" delay={1.5}>
         <div className="w-10 h-10 rounded-xl bg-[#EA4B71] flex items-center justify-center text-white shadow-lg shadow-pink-200/50">
            <Workflow size={20} />
         </div>
         <div className="text-left">
           <div className="text-xs text-gray-500 font-medium">Active Workflow</div>
           <div className="text-sm font-bold text-gray-900">Lead Gen Bot · Running</div>
         </div>
      </FloatingCard>

      {/* Background Gradients */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[1000px] h-[600px] bg-gradient-to-b from-blue-50 to-white rounded-full blur-3xl -z-10 opacity-60"></div>
    </section>
  );
};

const TechStack = () => (
  <section className="py-12 border-y border-gray-50 bg-[#FBFBFD]">
    <div className="max-w-7xl mx-auto px-6 text-center">
      <p className="text-xs font-semibold uppercase tracking-widest text-gray-400 mb-8">My Stack & Tools</p>
      <div className="flex flex-wrap justify-center gap-12 md:gap-20 opacity-50 grayscale hover:grayscale-0 transition-all duration-500">
        {['Claude', 'OpenAI', 'n8n', 'Svelte', 'Phoenix'].map((tool) => (
          <div key={tool} className="flex items-center space-x-2 group cursor-default">
             <span className="text-xl font-bold font-sans tracking-tight text-gray-800 group-hover:text-black transition-colors">{tool}</span>
          </div>
        ))}
      </div>
    </div>
  </section>
);

const BentoGrid = () => (
  <section id="content" className="py-24 bg-white">
    <div className="max-w-7xl mx-auto px-6">
      <div className="text-center max-w-3xl mx-auto mb-20">
        <h2 className="text-4xl md:text-5xl font-semibold tracking-tight text-gray-900 mb-6">
          Learn. Build. Automate.
        </h2>
        <p className="text-lg text-gray-500">
          Whether you're looking to master the latest LLMs or automate your entire agency, I've got the resources you need.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 auto-rows-[minmax(300px,auto)]">
        
        {/* Large Card - YouTube/Content */}
        <div className="md:col-span-2 rounded-3xl bg-[#F5F5F7] p-8 relative overflow-hidden group hover:shadow-2xl hover:shadow-gray-200 transition-all duration-500">
          <div className="relative z-10 h-full flex flex-col justify-between">
            <div>
              <div className="w-12 h-12 bg-white rounded-2xl flex items-center justify-center mb-6 shadow-sm">
                <Youtube className="text-red-600" />
              </div>
              <h3 className="text-2xl font-semibold mb-2 text-gray-900">Deep Dives & Tutorials</h3>
              <p className="text-gray-500 max-w-sm">
                Weekly videos breaking down complex topics like Claude Code artifacts, ChatGPT API integration, and advanced prompting strategies.
              </p>
            </div>
            <div className="mt-8 flex items-center space-x-2 text-sm font-medium text-gray-900 opacity-0 group-hover:opacity-100 transition-opacity transform translate-y-2 group-hover:translate-y-0">
              <span>Watch Now</span> <ChevronRight size={16} />
            </div>
          </div>
          {/* Decorative Visual */}
          <div className="absolute right-[-20px] bottom-[-20px] w-64 h-64 bg-gradient-to-tl from-red-100 to-white rounded-full opacity-0 group-hover:opacity-50 blur-3xl transition-opacity duration-700 ease-out"></div>
        </div>

        {/* Tall Card - Automation Services */}
        <div className="md:row-span-2 rounded-3xl bg-black p-8 text-white relative overflow-hidden group">
          <div className="relative z-10 h-full flex flex-col justify-between">
            <div>
              <div className="w-12 h-12 bg-gray-800 rounded-2xl flex items-center justify-center mb-6 border border-gray-700">
                <Zap className="text-yellow-400" />
              </div>
              <h3 className="text-2xl font-semibold mb-2">Automation Systems</h3>
              <p className="text-gray-400">Custom n8n workflows that run your business while you sleep.</p>
            </div>
            
            {/* Animated Terminal Visual */}
            <div className="mt-12 bg-gray-900 rounded-xl p-4 border border-gray-800 font-mono text-xs text-green-400 opacity-80">
               <div className="mb-2 text-gray-500 border-b border-gray-800 pb-2">workflow_engine.log</div>
               <div className="space-y-2">
                 <div className="flex gap-2"><span className="text-gray-600">09:00:01</span> <span>Fetching new leads...</span></div>
                 <div className="flex gap-2"><span className="text-gray-600">09:00:02</span> <span>Enriching data w/ GPT-4o</span></div>
                 <div className="flex gap-2"><span className="text-gray-600">09:00:04</span> <span>Drafting email...</span></div>
                 <div className="flex gap-2"><span className="text-gray-600">09:00:05</span> <span className="text-white bg-green-900/50 px-1 rounded">✓ Sent</span></div>
               </div>
            </div>
          </div>
        </div>

        {/* Small Card 1 - Prompt Engineering */}
        <div className="rounded-3xl bg-[#F5F5F7] p-8 relative overflow-hidden group hover:bg-purple-50 transition-colors duration-500">
           <div className="w-12 h-12 bg-white rounded-2xl flex items-center justify-center mb-6 shadow-sm">
              <Bot className="text-purple-600" />
           </div>
           <h3 className="text-xl font-semibold mb-2 text-gray-900">Prompting</h3>
           <p className="text-gray-500 text-sm">Library of system prompts for coding & writing.</p>
        </div>

        {/* Small Card 2 - Code/Consulting */}
        <div className="rounded-3xl bg-[#F5F5F7] p-8 relative overflow-hidden group hover:bg-green-50 transition-colors duration-500">
           <div className="w-12 h-12 bg-white rounded-2xl flex items-center justify-center mb-6 shadow-sm">
              <Code2 className="text-green-600" />
           </div>
           <h3 className="text-xl font-semibold mb-2 text-gray-900">Code</h3>
           <p className="text-gray-500 text-sm">Phoenix + Svelte integration patterns & snippets.</p>
        </div>

      </div>
    </div>
  </section>
);

const Footer = () => (
  <footer className="bg-white border-t border-gray-100 py-16">
    <div className="max-w-7xl mx-auto px-6 flex flex-col md:flex-row justify-between items-center md:items-start">
      <div className="mb-8 md:mb-0 text-center md:text-left">
        <div className="text-2xl font-bold tracking-tight text-gray-900 mb-4">Alex.ai</div>
        <p className="text-gray-500 text-sm max-w-xs">
          Empowering creators with the next generation of AI tools and automation.
        </p>
      </div>
      
      <div className="flex flex-col sm:flex-row space-y-4 sm:space-y-0 sm:space-x-12 text-sm text-gray-600">
        <a href="#" className="hover:text-black transition-colors">YouTube Channel</a>
        <a href="#" className="hover:text-black transition-colors">Newsletter</a>
        <a href="#" className="hover:text-black transition-colors">Twitter/X</a>
        <a href="#" className="hover:text-black transition-colors">GitHub</a>
      </div>
    </div>
    <div className="max-w-7xl mx-auto px-6 mt-16 pt-8 border-t border-gray-50 text-center text-xs text-gray-400">
      © 2025 Alex. All rights reserved.
    </div>
  </footer>
);

// --- Main App ---

export default function App() {
  return (
    <div className="min-h-screen bg-white font-sans text-gray-900 selection:bg-black selection:text-white antialiased">
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600&display=swap');
        
        body { font-family: 'Inter', sans-serif; }
        
        @keyframes float {
          0%, 100% { transform: translateY(0px); }
          50% { transform: translateY(-15px); }
        }
        
        .animate-float {
          animation: float 6s ease-in-out infinite;
        }

        @keyframes fadeInUp {
          from { opacity: 0; transform: translateY(20px); }
          to { opacity: 1; transform: translateY(0); }
        }

        .animate-fade-in-up {
          animation: fadeInUp 0.8s cubic-bezier(0.2, 0.8, 0.2, 1) forwards;
          opacity: 0;
        }

        .delay-100 { animation-delay: 100ms; }
        .delay-200 { animation-delay: 200ms; }
        .delay-300 { animation-delay: 300ms; }
      `}</style>
      
      <Navbar />
      <Hero />
      <TechStack />
      <BentoGrid />
      <Footer />
    </div>
  );
}

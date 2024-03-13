# Deforestation induced habitat fragmentation analysis
Analysing habitat fragmentation and deforestation in a small study area in San Javier, Bolivia.

## Acquiring images for the study area for time-series analysis


\documentclass{article}
\usepackage{graphicx} % Required for inserting images
\usepackage{tikz}
\usetikzlibrary{shapes.geometric, arrows}


\title{land monitoring}
\author{Sinoj Kokulasingam}
\date{March 2024}

\begin{document}

\tikzstyle{startstop} = [rectangle, rounded corners,text width=4.3cm, minimum width=3cm, minimum height=1cm,text centered, draw=black, fill=red!30]
\tikzstyle{io} = [trapezium, trapezium left angle=70,text width=3cm, trapezium right angle=110, minimum width=2cm, minimum height=1cm, text centered, draw=black, fill=blue!30]
\tikzstyle{process} = [rectangle, minimum width=3cm,text width=3cm, minimum height=1cm, text centered, draw=black, fill=orange!30]
\tikzstyle{decision} = [diamond, minimum width=3cm, minimum height=1cm, text centered, draw=black, fill=green!30]
\tikzstyle{arrow} = [thick,->,>=stealth]
\begin{tikzpicture}[node distance=2cm]
\node (clip) [process] {Clip to ROI};
\node (startStack1) [startstop,below of= clip,yshift=0.3cm, xshift=-0.3cm] {};
\node (startStack2) [startstop, below of= clip,yshift=0.2cm, xshift=-0.2cm]{};
\node (startStack3) [startstop,below of= clip, yshift=0.1cm, xshift=-0.1cm]{};
\node (imagesIN) [startstop,below of= clip] {Monthly images for year X};
% \node (scaleF) [process, left of=startStack1, xshift=-2cm] {Scaling factor};
\node (scaleF) [process, left of=startStack1, xshift=-2.3cm] {Scaling factor};
\node (cloudM) [process, right of=startStack1,xshift=2.6cm] {Cloud and cloud shadow mask};
\node (meanC) [process, below of=imagesIN] {Mean composite};
\node (postIMG) [startstop, below of= meanC] {Processed image for study area};
\node (RF) [io, below of= postIMG] {Random forest classifier};
\node (trainingData) [process, below of=meanC, xshift=5.3cm] {Training polygons};
\node (trainingSamples) [process, below of=trainingData,xshift=-1cm] {Training Samples};
\node (validSamples) [process, below of=trainingSamples] {Validation Samples};
\node (clsIMG) [startstop, below of= RF] {Classified image for year X};
\node (stats) [io, left of= clsIMG, xshift=-3cm] {Zonal statistics and patch metrics};
\node (errorM) [io, below of=validSamples] {Error Matrix, Validation accuracy, Training accuracy};

\node (startStack3) [startstop,below of= clsIMG,yshift=-3.6cm,xshift=-5.4cm] {};
\node (startStack2) [startstop,below of= clsIMG,yshift=-3.7cm,xshift=-5.3cm] {};
\node (startStack1) [startstop,below of= clsIMG,yshift=-3.8cm,xshift=-5.2cm] {};
\node (imagescls) [startstop,below of= clsIMG,yshift=-3.9cm, xshift=-5.1cm] {Classified images};
\node (temptraj) [process, right of=startStack3, xshift= 2.8cm] {Temporal trajectory rectification};
\node (imagescls2) [startstop,right of= imagescls, xshift=6.8cm,yshift=0.2cm] {};
\node (imagescls2) [startstop,right of= imagescls, xshift=6.9cm,yshift=0.1cm] {};

\node (imagescls1) [startstop,right of= imagescls, xshift=7cm] {Rectified classified images};






% \node (dec1) [decision, below of=pro1, yshift=-0.5cm] {Decision 1};
% \node (pro2a) [process, below of=dec1, yshift=-0.5cm] {Process 2a};
% \node (pro2b) [process, right of=dec1, xshift=2cm] {Process 2b};
% \node (out1) [io, below of=pro2a] {Output};
% \node (stop) [startstop, below of=out1] {Stop};






% \draw [arrow] (imagesIN) -- (clip);
% \draw [arrow] (clip) -- (scaleF);
% \draw [arrow] (scaleF) -- (cloudM);
% \draw [arrow] (cloudM) -- (meanC);
% \draw [arrow] (meanC) -- (postIMG);
% \draw [arrow] (dec1) -- (pro2b);
% \draw [arrow] (dec1) -- node[anchor=east] {yes} (pro2a);
% \draw [arrow] (dec1) -- node [anchor=south] {no} (pro2b);
% \draw [arrow] (pro2b) |- (pro1);
% \draw [arrow] (pro2a) -- (out1);
% \draw [arrow] (out1) -- (stop);




\end{tikzpicture}










\end{document}

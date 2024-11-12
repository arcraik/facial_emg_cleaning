function EEG = myfunc_hinf(EEG, VEOG, HEOG, hinf_p0_init, gamma, q)

Yf = EEG.data';
Rf = [VEOG.data', HEOG.data', ones(size(VEOG.data, 2),1)];
Pt = hinf_p0_init*eye(size(Rf,2)); 
g = [];
sh = zeros(size(Rf,1),size(Yf,2));
zh = zeros(size(Rf,1),size(Yf,2));  
wh = zeros(size(Rf,2),size(Yf,2));

disp('H-inf starts')

for n=1:size(Rf,1)         
    r  = Rf(n,:)';
    P  = pinv(  pinv(Pt) - (gamma^(-2))*(r*r')  );  
    g(:,1)      = (P*r)/(1+r'*P*r);
    for m=1:size(Yf,2)          
        y           = Yf(n,m);
        zh(n,m)     = r'*wh(:,m);   
        sh(n,m)     = y-zh(n,m);   
        wh(:,m)     = wh(:,m) + g(:,1)*sh(n,m);        
    end 
    Pt          = pinv (  (pinv(Pt))+ ((1-gamma^(-2))*(r*r')) ) + q*eye(size(Rf,2));
    WH          = wh;
end

disp('H-inf ends')

EEG.data = sh';
end
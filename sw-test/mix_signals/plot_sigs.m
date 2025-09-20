function plot_sigs(sig1, sig2, sig3, sig4, sig5)

  figure;
  subplot(5,1,1);
  plot(sig1, 'r');
  title('sig1');
  ylabel('V');
  grid on;

  subplot(5,1,2);
  plot(sig2, 'b');
  title('sig2');
  ylabel('V');
  grid on;

  subplot(5,1,3);
  plot(sig3);
  title('sig3');
  ylabel('V');
  grid on;

  subplot(5,1,4);
  plot(sig4);
  title('sig4');
  ylabel('V');
  grid on;

  subplot(5,1,5);
  plot(sig5, 'g');
  title('sig5');
  xlabel('t');
  ylabel('V');
  grid on;

end
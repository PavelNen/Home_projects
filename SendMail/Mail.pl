use Net::SMTP; # используем класс для отправки e-mail
my $mail_server = 'smpt.mail.ru';         # почтовый сервер
my $to_user     = 'pavelnen@gmail.com'; # получатель
my $from_user   = 'PashaWithPerl';  # отправитель

$smtp = Net::SMTP->new(Host=>$mail_server, Port=>25, Debug => 1);# соединяюсь
$smtp->auth('nps-11@mail.ru','Topsecret18!');
$smtp->mail($from_user);                   # пишу
$smtp->to($to_user);                       # получателю
$smtp->data();                             # письмо
$smtp->datasend("To: $to_user\n");         #
$smtp->datasend("Subject: Lessons on Perl\n");
$smtp->datasend("\n");
$smtp->datasend("Если ты читаешь это письмо, то у меня получилось!\n");
$smtp->datasend("Да здравствует Перл!\n");
$smtp->dataend();                          # заканчиваю
$smtp->quit;                               # отсоединяюсь

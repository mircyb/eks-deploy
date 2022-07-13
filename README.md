variables.tf에 클러스터 이름 변수 수정

providers.tf에 eks profile 이름 설정

vpc.tf에 vpc와 서브넷의 cidr 설정


3개의 node를 가진 eks 클러스터가 배포되며
이  클러스터에 접근할수 있는 bastion노드가 같이 배포됨
mariadb rdb 

상세 내용 수정시 각 항목별 tf파일을 직접 수정하여 사용

{
  force = true;
  settings = [
    {
      name = "Monkeytype";
      url = "https://monkeytype.com/";
    }
    {
      name = "Docker Compose Environment";
      url = "https://env.dev/guides/docker-compose-env-variables";
    }
    {
      name = "dCode";
      url = "https://www.dcode.fr/en#f6";
    }
    {
      name = "Bookmarks Toolbar";
      toolbar = true;
      bookmarks = [
        {
          name = "hda";
          bookmarks = [
            {
              name = "HDA Mail";
              url = "https://webmail.stud.h-da.de/stud/index.php";
            }
            {
              name = "Moodle HDA";
              url = "https://lernen.h-da.de/";
            }
            {
              name = "my hda";
              url = "https://my.h-da.de/";
            }
          ];
        }
        {
          name = "Bitwarden";
          url = "https://vault.bitwarden.com/";
        }
        {
          name = "c24";
          bookmarks = [
            {
              name = "bitbucket";
              url = "https://bitbucket.org/check24/workspace/overview/";
            }
            {
              name = "Links (BO/Int/Stag)";
              url = "https://confluence.check24.de/spaces/VETH/overview";
            }
            {
              name = "src";
              bookmarks = [
                {
                  name = "thv-mobile";
                  url = "https://bitbucket.org/check24/thv-mobile/src/integration/";
                }
                {
                  name = "thv-core";
                  url = "https://bitbucket.org/check24/thv-core/src/integration/";
                }
              ];
            }
            {
              name = "Docs";
              bookmarks = [
                {
                  name = "c24wiki";
                  url = "https://confluence.check24.de/pages/viewpage.action?spaceKey=VETH&title=Tierversicherungen+Projekt-Urls";
                }
                {
                  name = "Web API | CHECK24 Factory";
                  url = "https://docs.hintl.check24.com/docs/app/common/web-api";
                }
              ];
            }
            {
              name = "HR";
              bookmarks = [
                {
                  name = "absence.io";
                  url = "https://app.absence.io/#/mycalendar";
                }
                {
                  name = "P&I LogaHR | Mein Profil";
                  url = "https://check24.pi-asp.de/loga3/private/layout?action=afterlogin";
                }
                {
                  name = "P&I LogaHR";
                  url = "https://check24.pi-asp.de/loga3/private/layout?action=afterlogin";
                }
              ];
            }
            {
              name = "test data";
              url = "https://confluence.check24.de/spaces/VETH/pages/1296616735/04.1+-+Test+data+for+purchase";
            }
            {
              name = "THV Standup board";
              url = "https://c24-sach.atlassian.net/jira/dashboards/10430";
            }
            {
              name = "P&I LogaHR | Dashboard";
              url = "https://check24.pi-asp.de/loga3/private/layout?action=afterlogin";
            }
            {
              name = "Grafana";
              url = "https://grafana.hundehaftpflichtversicherungen.check24.de/d/adj6rm9nvmupsb/tv-board-new?orgId=1&from=now%2FM&to=now%2FM&timezone=browser&var-environment=production&refresh=5s";
            }
            {
              name = "Office-IT Hub [\"thv\",\"pet\",\"blue\"]";
              url = "https://hub.o.check24.de/services";
            }
            {
              name = "ExpenseTools";
              url = "https://expenses.finance.check24.de/dashboard";
            }
            {
              name = "Kibana";
              url = "https://kibana.hundehaftpflichtversicherungen.check24.de/app/home#/";
            }
            {
              name = "Ticket List [\"thv\",\"pet\",\"blue\"] [*]";
              url = "https://c24-sach.atlassian.net/jira/software/c/projects/FFMTHV/list?jql=project%20%3D%20%22FFMTHV%22%20AND%20status%20%3D%20Open%20AND%20assignee%20%3D%20empty%20ORDER%20BY%20%22cf%5B10019%5D%22%20ASC";
            }
            {
              name = "My Tickets [\"thv\",\"pet\",\"blue\"] [*]";
              url = "https://c24-sach.atlassian.net/jira/software/c/projects/FFMTHV/list?jql=project%20%3D%20%22FFMTHV%22%20and%20assignee%20%3D%20currentUser()%20ORDER%20BY%20updated%20DESC%2C%20created%20DESC%2C%20Rank%20ASC&groupBy=status";
            }
            {
              name = "TICKET LIST [\"thv\",\"pet\",\"blue\"]";
              url = "https://c24-sach.atlassian.net/jira/software/c/projects/FFMTHV/boards/729?assignee=unassigned";
            }
          ];
        }
        {
          name = "misc";
          bookmarks = [
            {
              name = "Stat Rethinking";
              url = "https://github.com/rmcelreath/stat_rethinking_2026";
            }
            {
              name = "Blog – Evgeni Chasnovski";
              url = "https://echasnovski.com/blog.html";
            }
          ];
        }
        {
          name = "proton";
          bookmarks = [
            {
              name = "Mail";
              url = "https://mail.proton.me/";
            }
          ];
        }
        {
          name = "THV Links";
          bookmarks = [
            {
              name = "Kibana";
              bookmarks = [
                {
                  name = "Kibana STAG";
                  url = "https://kibana.hundehaftpflichtversicherungen.check24-test.de/";
                }
                {
                  name = "Kibana Live";
                  url = "https://kibana.hundehaftpflichtversicherungen.check24.de/";
                }
                {
                  name = "Kibana INT";
                  url = "https://kibana.hundehaftpflichtversicherungen.check24-int.de/";
                }
              ];
            }
            {
              name = "Mobile";
              bookmarks = [ ];
            }
            {
              name = "Desktop";
              bookmarks = [ ];
            }
            {
              name = "BO";
              bookmarks = [
                {
                  name = "BO INT";
                  url = "https://integration.bo.hundehaftpflichtversicherungen.check24-int.de/app/main/";
                }
                {
                  name = "BO STAG";
                  url = "https://bo.hundehaftpflichtversicherungen.check24-test.de/app/main/";
                }
                {
                  name = "BO Live";
                  url = "https://bo.hundehaftpflichtversicherungen.check24.de/app/main/";
                }
              ];
            }
          ];
        }
      ];
    }
  ];
}

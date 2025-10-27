import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Activity, Heart, Users, TrendingUp } from "lucide-react";
import { useNavigate } from "react-router-dom";

const Dashboard = () => {
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState("");

  const { data: patients, isLoading } = useQuery({
    queryKey: ["patients"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("patients")
        .select("*")
        .order("created_at", { ascending: false });
      
      if (error) throw error;
      return data;
    },
  });

  const { data: stats } = useQuery({
    queryKey: ["dashboard-stats"],
    queryFn: async () => {
      const [patientsCount, testsCount, logsCount] = await Promise.all([
        supabase.from("patients").select("*", { count: "exact", head: true }),
        supabase.from("standup_tests").select("*", { count: "exact", head: true }),
        supabase.from("symptom_logs").select("*", { count: "exact", head: true }),
      ]);

      return {
        totalPatients: patientsCount.count || 0,
        totalTests: testsCount.count || 0,
        totalLogs: logsCount.count || 0,
      };
    },
  });

  const filteredPatients = patients?.filter((patient) =>
    `${patient.first_name} ${patient.last_name}`
      .toLowerCase()
      .includes(searchQuery.toLowerCase())
  );

  return (
    <div className="bg-background">
      <div className="container mx-auto py-8 px-4 space-y-8">
        <div className="flex flex-col gap-4">
          <h1 className="text-4xl font-bold text-foreground">POTS Clinician Dashboard</h1>
          <p className="text-muted-foreground">
            Monitor and analyze patient data for Postural Orthostatic Tachycardia Syndrome
          </p>
        </div>

        <div className="grid gap-4 md:grid-cols-3">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Patients</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-primary">{stats?.totalPatients || 0}</div>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Stand-Up Tests</CardTitle>
              <Activity className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-primary">{stats?.totalTests || 0}</div>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Symptom Logs</CardTitle>
              <Heart className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-primary">{stats?.totalLogs || 0}</div>
            </CardContent>
          </Card>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Patient Directory</CardTitle>
            <CardDescription>Select a patient to view their detailed records</CardDescription>
            <Input
              placeholder="Search patients..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="max-w-sm"
            />
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="text-center py-8 text-muted-foreground">Loading patients...</div>
            ) : filteredPatients && filteredPatients.length > 0 ? (
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {filteredPatients.map((patient) => (
                  <Card
                    key={patient.id}
                    className="cursor-pointer hover:border-primary transition-colors"
                    onClick={() => navigate(`/patient/${patient.id}`)}
                  >
                    <CardHeader>
                      <CardTitle className="text-lg">
                        {patient.first_name} {patient.last_name}
                      </CardTitle>
                      <CardDescription>
                        DOB: {new Date(patient.date_of_birth).toLocaleDateString()}
                      </CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span className="text-muted-foreground">Sex:</span>
                        <span className="font-medium">{patient.sex_assigned_at_birth}</span>
                      </div>
                      {patient.pots_diagnosis_date && (
                        <div className="flex justify-between text-sm">
                          <span className="text-muted-foreground">POTS Dx:</span>
                          <span className="font-medium">
                            {new Date(patient.pots_diagnosis_date).toLocaleDateString()}
                          </span>
                        </div>
                      )}
                      <Button className="w-full mt-4" variant="outline">
                        View Details
                      </Button>
                    </CardContent>
                  </Card>
                ))}
              </div>
            ) : (
              <div className="text-center py-8 text-muted-foreground">
                No patients found
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default Dashboard;

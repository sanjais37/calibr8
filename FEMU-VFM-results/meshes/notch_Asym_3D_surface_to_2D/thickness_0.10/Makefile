NAMES = notches_Asym
NAME_3D = notch3D_Asym
NAME_2D = notch2D_Asym

GMODEL_DIR=${CALIBR8DIR}/install/gmodel
GMSH=${CALIBR8DIR}/install/gmsh/bin/gmsh
FROM_GMSH=${CALIBR8DIR}/install/scorec/bin/from_gmsh
SPLIT=${CALIBR8DIR}/install/scorec/bin/split

#GMODEL_DIR=${CALIBR8DIR}/flavor/${CAPP_FLAVOR}/install/gmodel
#GMSH=/Applications/Gmsh.app/Contents/MacOS/gmsh
#FROM_GMSH=${CALIBR8DIR}/flavor/${CAPP_FLAVOR}/install/scorec/bin/from_gmsh
#SPLIT=${CALIBR8DIR}/flavor/${CAPP_FLAVOR}/install/scorec/bin/split

all: ${NAME_3D}.smb ${NAME_2D}.smb

${NAMES}.geo:
	mpicxx -std=c++11 ${NAMES}.cpp -o ${NAMES} -I${GMODEL_DIR}/include -L${GMODEL_DIR}/lib -lgmodel
	./${NAMES}

${NAME_3D}.msh: ${NAMES}.geo
	${GMSH} -3 ${NAME_3D}.geo -o ${NAME_3D}.msh -format msh2

${NAME_3D}.smb: ${NAME_3D}.msh
	${FROM_GMSH} ${NAME_3D}.dmg ${NAME_3D}.msh ${NAME_3D}.smb

${NAME_2D}.msh: ${NAMES}.geo
	${GMSH} -3 ${NAME_2D}.geo -o ${NAME_2D}.msh -format msh2

${NAME_2D}.smb: ${NAME_2D}.msh
	${FROM_GMSH} ${NAME_2D}.dmg ${NAME_2D}.msh ${NAME_2D}.smb
	
	
all: ${NAME_3D}_4p.smb ${NAME_2D}_4p.smb

${NAME_3D}_4p.smb: ${NAME_3D}.msh
	mpirun -n 4 ${SPLIT} ${NAME_3D}.dmg ${NAME_3D}.smb ${NAME_3D}_4p.smb 4
	
${NAME_2D}_4p.smb: ${NAME_2D}.msh
	mpirun -n 4 ${SPLIT} ${NAME_2D}.dmg ${NAME_2D}.smb ${NAME_2D}_4p.smb 4	
	

clean:
	rm -rf ${NAME_3D} ${NAME_3D}.geo ${NAME_3D}.dmg ${NAME_3D}.msh ${NAME_3D}*.smb
	rm -rf ${NAME_2D} ${NAME_2D}.geo ${NAME_2D}.dmg ${NAME_2D}.msh ${NAME_2D}*.smb
